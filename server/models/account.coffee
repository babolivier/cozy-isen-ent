cozydb = require 'cozydb'
conf    = require '../../conf.coffee'

# Public: the account model
class Account extends cozydb.CozyModel
    @docType: 'Account'

    # Public: allowed fields for an account
    @schema:
        label: String               # human readable label for the account
        name: String                # user name to put in sent mails
        login: String               # IMAP & SMTP login
        password: String            # IMAP & SMTP password
        accountType: String         # "IMAP" or "TEST"
        oauthProvider: String       # If authentication use OAuth (only value allowed for now: GMAIL)
        oauthAccessToken: String    # AccessToken
        oauthRefreshToken: String   # RefreshToken (in order to get an access_token)
        oauthTimeout: Number        # AccessToken timeout
        initialized: Boolean        # Is the account ready ?
        smtpServer: String          # SMTP host
        smtpPort: Number            # SMTP port
        smtpSSL: Boolean            # Use SSL
        smtpTLS: Boolean            # Use STARTTLS
        smtpLogin: String           # SMTP login, if different from default
        smtpPassword: String        # SMTP password, if different from default
        smtpMethod: String          # SMTP Auth Method
        imapLogin: String           # IMAP login
        imapServer: String          # IMAP host
        imapPort: Number            # IMAP port
        imapSSL: Boolean            # Use SSL
        imapTLS: Boolean            # Use STARTTLS
        inboxMailbox: String        # INBOX Maibox id
        flaggedMailbox: String      # \Flag Mailbox id
        draftMailbox:   String      # \Draft Maibox id
        sentMailbox:    String      # \Sent Maibox id
        trashMailbox:   String      # \Trash Maibox id
        junkMailbox:    String      # \Junk Maibox id
        allMailbox:     String      # \All Maibox id
        favorites:      [String]    # [String] Maibox id of displayed boxes
        patchIgnored:   Boolean     # has patchIgnored been applied ?
        supportRFC4551: Boolean     # does the account support CONDSTORE ?
        signature:      String      # Signature to add at the end of messages
            
    @getParams: =>
        if conf.mail
            params = conf.mailParams
        else
            params = null
        params

    @loadThenCreate: (credentials, callback) =>
        params = @getParams()
        username = credentials.username
        password = credentials.password
        @getMailAddress username, (err, email) =>
            if err
                callback err
            else
                data =
                    label: params.label
                    name: username
                    login: email
                    password: password
                    accountType: "IMAP"
                    smtpServer: params.smtpServer
                    smtpPort: params.smtpPort
                    smtpSSL: params.smtpSSL
                    smtpTLS: params.smtpTLS
                    smtpLogin: username
                    smtpMethod: params.smtpMethod
                    imapLogin: username
                    imapServer: params.imapServer
                    imapPort: params.imapPort
                    imapSSL: params.imapSSL
                    imapTLS: params.imapTLS
                @createIfValid data, (err, created) =>
                    if err
                        callback err
                    else
                        callback null, created
                
    @getMailAddress: (username, callback) =>
        # We'll need to access the Konnector in order to get the
        # e-mail address
        params = @getParams()
        if params.viaKonnector
            email = null
            Konnector = cozydb.getModel 'Konnector',
                slug: String
                fieldValues: Object
                password: String
                lastImport: Date
                lastAutoImport: Date
                isImporting: Boolean
                importInterval: String
                errorMessage: String


            Konnector.request "all", (err, konnectors) =>
                if err
                    callback err
                else
                    i = 0;
                    konnectors.forEach (konnector) =>
                        i++
                        if konnector.slug is params.konnectorSlug
                            email = konnector.fieldValues.email
                        if i is konnectors.length
                            callback null, email
        else 
            callback null, username+"@isen-bretagne.fr"

    @exists: (callback) =>
        params = @getParams()
        @request 'all', (err, accounts) =>
            if err
                callback err
            else
                found = false
                if accounts.length > 0
                    i = 0
                    accounts.forEach (account) =>
                        i++
                        if account.imapServer is params.imapServer
                            found = true
                        if i is accounts.length
                            callback null, found
                else
                    callback null, found

    # Public: fetch the mailbox tree of a new {Account}
    # if the fetch succeeds, create the account and mailboxes in couch
    # else throw an {AccountConfigError}
    # returns fast once the account and mailboxes has been created
    # in the background, proceeds to download mails
    #
    # data - account parameters
    #
    # Returns (callback) {Account} the created account
    @createIfValid: (data, callback) ->
        data.initialized = true
        account = new Account data
        toFetch = null

        async.series [

            (cb) ->
                log.debug "create#cozy"
                Account.create account, (err, created) ->
                    return cb err if err
                    account = created
                    cb null
            (cb) ->
                log.debug "create#refreshBoxes"
                account.imap_refreshBoxes (err, boxes) ->
                    return cb err if err
                    toFetch = boxes
                    cb null

            (cb) ->
                log.debug "create#scan"
                account.imap_scanBoxesForSpecialUse toFetch, cb
        ], (err) ->
            return callback err if err
            callback null, account

    # Public: wrap an async function (the operation) to get a connection from
    # the pool before performing it and release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAP: (operation, callback) ->
        ImapPool.get(@id).doASAP operation, callback

    # Public: get the account's mailboxes in imap
    # also update the account supportRFC4551 attribute if needed
    #
    # Returns (callback) {Array} of nodeimap mailbox raw {Object}s
    imap_getBoxes: (callback) ->
        log.debug "getBoxes"
        supportRFC4551 = null
        @doASAP (imap, cb) ->
            supportRFC4551 = imap.serverSupports 'CONDSTORE'
            imap.getBoxesArray cb
        , (err, boxes) =>
            return callback err, [] if err

            if supportRFC4551 isnt @supportRFC4551
                log.debug "UPDATING ACCOUNT #{@id} rfc4551=#{@supportRFC4551}"
                @updateAttributes {supportRFC4551}, (err) ->
                    log.warn "fail to update account #{err.stack}" if err
                    callback null, boxes or []
            else
                callback null, boxes or []

    # Public: refresh the account's mailboxes
    #
    # Returns (callback) {Array} of nodeimap mailbox raw {Object}s
    imap_refreshBoxes: (callback) ->
        log.debug "imap_refreshBoxes"
        account = this

        async.series [
            (cb) => Mailbox.getBoxes @id, cb
            (cb) => @imap_getBoxes cb
        ], (err, results) ->
            log.debug "refreshBoxes#results"
            return callback err if err
            [cozyBoxes, imapBoxes] = results
            return callback null, cozyBoxes, [] if account.isTest()

            toFetch = []
            toDestroy = []
            # find new imap boxes
            boxToAdd = imapBoxes.filter (box) ->
                not _.findWhere(cozyBoxes, path: box.path)

            # discrimate cozyBoxes to fetch and to remove
            for cozyBox in cozyBoxes
                if _.findWhere(imapBoxes, path: cozyBox.path)
                    toFetch.push cozyBox
                else
                    toDestroy.push cozyBox

            log.debug "refreshBoxes#results2", boxToAdd.length,
                toFetch.length, toDestroy.length

            async.eachSeries boxToAdd, (box, cb) ->
                log.debug "refreshBoxes#creating", box.label
                box.accountID = account.id
                Mailbox.create box, (err, created) ->
                    return cb err if err
                    toFetch.push created
                    cb null
            , (err) ->
                return callback err if err
                callback null, toFetch, toDestroy

    # Public: set an account xxxMailbox attributes & favorites
    # from a list of mailbox
    #
    # boxes - an array of {Mailbox} to scan
    #
    # Returns (callback) the updated account
    imap_scanBoxesForSpecialUse: (boxes, callback) ->
        useRFC6154 = false
        inboxMailbox = null
        boxAttributes = Object.keys Mailbox.RFC6154

        changes = {initialized: true}

        boxes.map (box) ->
            type = box.RFC6154use()
            if box.isInbox()
                # save it in scope, so we dont erase it
                inboxMailbox = box.id

            else if type
                unless useRFC6154
                    useRFC6154 = true
                    # remove previous guesses
                    for attribute in boxAttributes
                        changes[attribute] = null
                log.debug 'found', type
                changes[type] = box.id

            # do not attempt fuzzy match if the server uses RFC6154
            else if not useRFC6154 and type = box.guessUse()
                log.debug 'found', type, 'guess'
                changes[type] = box.id

            return box

        # pick the default 4 favorites box
        priorities = [
            'inboxMailbox', 'allMailbox',
            'sentMailbox', 'draftMailbox'
        ]

        changes.inboxMailbox = inboxMailbox
        changes.favorites = []

        # see if we have some of the priorities box
        for type in priorities
            id = changes[type]
            if id
                changes.favorites.push id

        # if we dont have our 4 favorites, pick at random
        for box in boxes when changes.favorites.length < 4
            if box.id not in changes.favorites and box.isSelectable()
                changes.favorites.push box.id

        @updateAttributes changes, callback

    # Public: find an account by id
    # cozydb's find can return no error and no account (if id isnt an account)
    # this version always return one or the other
    #  id - id of the account to find
    #  callback - Function(Error err, Account account)
    @findSafe: (id, callback) ->
        Account.find id, (err, account) ->
            return callback err if err
            return callback new NotFound "Account##{id}" unless account
            callback null, account
    
    # Public: check if an account is test (created by fixtures)
    #
    # Returns {Boolean} if this account is a test account
    isTest: ->
        @accountType is 'TEST'

module.exports = Account
# There is a circular dependency between ImapProcess & Account
# node handle if we require after module.exports definition
Mailbox     = require './mailbox'
ImapPool = require '../imap/pool'
async = require 'async'
log = require('../utils/logging')(prefix: 'models:account')
_ = require 'lodash'