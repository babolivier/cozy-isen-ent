cozydb = require 'cozydb'

# Public: the mailbox model
class Mailbox extends cozydb.CozyModel
    @docType: 'Mailbox'
    @schema:
        accountID: String        # Parent account
        label: String            # Human readable label
        path: String             # IMAP path
        lastSync: String         # Date.ISOString of last full box synchro
        tree: [String]           # Normalized path as Array
        delimiter: String        # delimiter between this box and its children
        uidvalidity: Number      # Imap UIDValidity
        attribs: [String]        # [String] Attributes of this folder
        lastHighestModSeq: String # Last highestmodseq successfully synced
        lastTotal: Number         # Last imap total number of messages in box

    # map of account's attributes -> RFC6154 special use box attributes
    @RFC6154:
        draftMailbox:   '\\Drafts'
        sentMailbox:    '\\Sent'
        trashMailbox:   '\\Trash'
        allMailbox:     '\\All'
        junkMailbox:    '\\Junk'
        flaggedMailbox: '\\Flagged'

    # Public: create a box in imap and in cozy
    #
    # account - {Account} to create the box in
    # parent - {Mailbox} to create the box in
    # label - {String} label of the new mailbox
    #
    # Returns (callback) {Mailbox}
    @imapcozy_create: (account, parent, label, callback) ->
        if parent
            path = parent.path + parent.delimiter + label
            tree = parent.tree.concat label
        else
            path = label
            tree = [label]

        mailbox =
            accountID: account.id
            label: label
            path: path
            tree: tree
            delimiter: parent?.delimiter or '/'
            attribs: []

        ImapPool.get(account.id).doASAP (imap, cbRelease) ->
            imap.addBox2 path, cbRelease
        , (err) ->
            return callback err if err
            Mailbox.create mailbox, callback


    # Public: find selectable mailbox for an account ID
    # as an array
    #
    # accountID - id of the account
    #
    # Returns (callback) {Array} of {Mailbox}
    @getBoxes: (accountID, callback) ->
        Mailbox.rawRequest 'treeMap',
            startkey: [accountID]
            endkey: [accountID, {}]
            include_docs: true

        , (err, rows) ->
            return callback err if err
            rows = rows.map (row) ->
                new Mailbox row.doc

            callback null, rows

    # Public: find selectable mailbox for an account ID
    # as an id indexed object with only path attributes
    # @TODO : optimize this with a map/reduce request
    #
    # accountID - id of the account
    #
    # Returns (callback) [{Mailbox}]
    @getBoxesIndexedByID: (accountID, callback) ->
        Mailbox.getBoxes accountID, (err, boxes) ->
            return callback err if err
            boxIndex = {}
            boxIndex[box.id] = box for box in boxes
            callback null, boxIndex

    # Public: remove mailboxes linked to an account that doesn't exist
    # in cozy.
    # @TODO : optimize this with a map destroy
    #
    # existing - {Array} of {String} ids of existing accounts
    #
    # Returns (callback) [{Mailbox}] all remaining mailboxes
    @removeOrphans: (existings, callback) ->
        log.debug "removeOrphans"
        Mailbox.rawRequest 'treemap', {}, (err, rows) ->
            return callback err if err

            boxes = []

            async.eachSeries rows, (row, cb) ->
                accountID = row.key[0]
                if accountID in existings
                    boxes.push row.id
                    cb null
                else
                    log.debug "removeOrphans - found orphan", row.id
                    Mailbox.destroy row.id, (err) ->
                        log.error 'failed to delete box', row.id if err
                        cb null

            , (err) ->
                callback err, boxes


    # Public: wrap an async function (the operation) to get a connection from
    # the pool before performing it and release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAP: (operation, callback) ->
        ImapPool.get(@accountID).doASAP operation, callback

    # Public: wrap an async function (the operation) to get a connection from
    # the pool and open the mailbox without error before performing it and
    # release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAPWithBox: (operation, callback) ->
        ImapPool.get(@accountID).doASAPWithBox @, operation, callback

    # Public: wrap an async function (the operation) to get a connection from
    # the pool and open the mailbox without error before performing it and
    # release the connection once it is done. The operation will be put at the
    # bottom of the queue.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doLaterWithBox: (operation, callback) ->
        ImapPool.get(@accountID).doLaterWithBox @, operation, callback

    # Public: refresh mails in this box
    #
    # Returns (callback) {Boolean} shouldNotif whether or not new unread mails
    # have been fetched in this fetch
    imap_refresh: (options, callback) ->
        log.debug "refreshing box"
        if not options.supportRFC4551
            log.debug "account doesnt support RFC4551"
            @imap_refreshDeep options, callback

        else if @lastHighestModSeq
            @imap_refreshFast options, (err, shouldNotif) =>
                if err
                    log.warn "refreshFast fail (#{err.stack}), trying deep"
                    options.storeHighestModSeq = true
                    @imap_refreshDeep options, callback

                else
                    log.debug "refreshFastWorked"
                    callback null, shouldNotif

        else
            log.debug "no highestmodseq, first refresh ?"
            options.storeHighestModSeq = true
            @imap_refreshDeep options, callback


    # Public: refresh mails in this box using rfc4551. This is similar to
    # {::imap_refreshDeep} but faster if the server supports RFC4551.
    #
    # First, we ask the server for all updated messages since last
    # refresh. {Mailbox::_refreshGetImapStatus}
    #
    # Then we apply these changes in {Mailbox::_refreshCreatedAndUpdated}
    #
    # Because RFC4551 doesnt give a way for the server to indicate expunged
    # messages, at this point, we have all new and updated messages, but we
    # may still have messages in cozy that were expungeds in IMAP.
    # We refresh deletion if needed in {Mailbox::_refreshDeleted}
    #
    # Finally we store the new highestmodseq, so we can ask for changes
    # since this refresh. We also store the IMAP number of message because
    # it can be different from the cozy one due to twin messages.
    #
    # Returns (callback) {Boolean} shouldNotif whether or not new unread mails
    # have been fetched in this fetch
    imap_refreshFast: (options, callback) ->
        box = this

        noChange = false
        box._refreshGetImapStatus box.lastHighestModSeq, (err, status) ->
            return callback err if err
            {changes, highestmodseq, total} = status

            box._refreshCreatedAndUpdated changes, (err, info) ->
                return callback err if err
                log.debug "_refreshFast#aftercreates", info
                shouldNotif = info.shouldNotif
                noChange or= info.noChange

                box._refreshDeleted total, info.nbAdded, (err, info) ->
                    return callback err if err
                    log.debug "_refreshFast#afterdelete", info
                    noChange or= info.noChange

                    if noChange
                        #@TODO : may be we should store lastSync
                        callback null, false

                    else
                        changes =
                            lastHighestModSeq: highestmodseq
                            lastTotal: total
                            lastSync: new Date().toISOString()

                        box.updateAttributes changes, (err) ->
                            callback err, shouldNotif

    # Private: Fetch some information from recent changes to the box
    #
    # modseqno - {String} the last checkpointed modification sequence
    #
    # Returns (callback) an {Object} with properties
    #       :changes - an {Object} with keys=uid, values=[mid, flags]
    #       :highestmodseq - the highest modification sequence of this box
    #       :total - total number of messages in this box
    _refreshGetImapStatus: (modseqno, callback) ->
        @doLaterWithBox (imap, imapbox, cbReleaseImap) ->
            highestmodseq = imapbox.highestmodseq
            total = imapbox.messages.total
            changes = {}
            if highestmodseq is modseqno
                cbReleaseImap null, {changes, highestmodseq, total}
            else
                imap.fetchMetadataSince modseqno, (err, changes) ->
                    cbReleaseImap err, {changes, highestmodseq, total}

        , callback

    # Public: refresh some mails from this box
    #
    # options - the parameter {Object}
    #   :limitByBox - {Number} limit nb of message by box
    #   :firstImport - {Boolean} is this part of the first import of an account
    #
    # Returns (callback) {Boolean} shouldNotif whether or not new unread mails
    # have been fetched in this fetch
    imap_refreshDeep: (options, callback) ->
        {limitByBox, firstImport, storeHighestModSeq} = options
        log.debug "imap_refreshDeep", limitByBox
        step = RefreshStep.initial options

        @imap_refreshStep step, (err, info) =>
            log.debug "imap_refreshDeepEnd", limitByBox
            return callback err if err
            unless limitByBox
                changes = lastSync: new Date().toISOString()
                if storeHighestModSeq
                    changes.lastHighestModSeq = info.highestmodseq
                    changes.lastTotal = info.total
                @updateAttributes changes, callback
            else
                callback null, info.shouldNotif

    # Public: apply a mixed bundle of ops
    #
    # ops - a operation bundle
    #       :toFetch - {Array} of {Object}(mid, uid) msg to fetch
    #       :toRemove - {Array} of {String} ids of cozy messages to remove
    #       :flagsChange - {Array} of {Object}(id, flags) changes to make
    # isFirstImport - {Boolean} is this part of the first import of account
    #
    # Returns (callback) shouldNotif - {Boolean} was a new unread message
    # imported
    applyOperations: (ops, isFirstImport, callback) ->
        {toFetch, toRemove, flagsChange} = ops
        nbTasks = toFetch.length + toRemove.length + flagsChange.length

        outShouldNotif = false

        if nbTasks > 0
            reporter = ImapReporter.boxFetch @, nbTasks, isFirstImport

            async.series [
                (cb) => @applyToRemove     toRemove,    reporter, cb
                (cb) => @applyFlagsChanges flagsChange, reporter, cb
                (cb) =>
                    @applyToFetch toFetch, reporter, (err, shouldNotif) ->
                        return cb err if err
                        outShouldNotif = shouldNotif
                        cb null
            ], (err) ->
                if err
                    reporter.onError err
                reporter.onDone()
                callback err, outShouldNotif
        else
            callback null, outShouldNotif

    # Public: refresh part of a mailbox
    # @TODO : recursion is complicated, refactor this using async.while
    #
    # laststep - {RefreshStep} can be null, step references            -
    #
    # Returns (callback) an info {Object} with properties
    #       :shouldNotif - {Boolean} was a new unread message imported
    #       :highestmodseq - {String} the box highestmodseq at begining
    imap_refreshStep: (laststep, callback) ->
        log.debug "imap_refreshStep", laststep
        box = this
        @getDiff laststep, (err, ops, step) =>
            log.debug "imap_refreshStep#diff", err, ops

            return callback err if err

            info =
                shouldNotif: false
                total: step.total
                highestmodseq: step.highestmodseq

            unless ops
                return callback null, info
            else
                firstImport = laststep.firstImport
                @applyOperations ops, firstImport, (err, shouldNotif) =>
                    return callback err if err

                    # next step
                    @imap_refreshStep step, (err, infoNext) ->
                        return callback err if err
                        info.shouldNotif = shouldNotif or infoNext.shouldNotif
                        callback null, info

    # Public: get this box usage by special attributes
    #
    # Returns {String} the account attribute to set or null
    RFC6154use: ->
        for field, attribute of Mailbox.RFC6154
            if attribute in @attribs
                return field

    # Public: is this box the inbox
    #
    # Returns {Boolean} if its the INBOX
    isInbox: -> @path is 'INBOX'

    # Public: try to guess this box usage by its name
    #
    # Returns {String} the account attribute to set or null
    guessUse: ->
        path = @path.toLowerCase()
        if /sent/i.test path
            return 'sentMailbox'
        else if /draft/i.test path
            return 'draftMailbox'
        else if /flagged/i.test path
            return 'flaggedMailbox'
        else if /trash/i.test path
            return 'trashMailbox'
        # @TODO add more

    # Public: is this box selectable (ie. can contains mail)
    #
    # Returns {Boolean} if its selectable
    isSelectable: ->
        '\\Noselect' not in (@attribs or [])

module.exports = Mailbox
log = require('../utils/logging')(prefix: 'models:mailbox')
_ = require 'lodash'
async = require 'async'
mailutils = require '../utils/jwz_tools'
ImapPool = require '../imap/pool'
ImapReporter = require '../imap/reporter'
{Break, NotFound} = require '../utils/errors'
{FETCH_AT_ONCE} = require '../utils/constants'

require('../utils/socket_handler').wrapModel Mailbox, 'mailbox'
