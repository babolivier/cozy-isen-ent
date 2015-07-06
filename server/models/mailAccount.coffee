# See documentation on https://github.com/aenario/cozydb/

cozydb = require 'cozydb'

module.exports = class Account extends cozydb.CozyModel
    @docType: 'Account'

    @schema:
      label: String               # human readable label for the account
      name: String                # user name to put in sent mails
      login: String               # IMAP & SMTP login
      password: String            # IMAP & SMTP password
      accountType: String         # "IMAP" or "TEST"
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
      draftMailbox: String        # \Draft Maibox id
      sentMailbox: String         # \Sent Maibox id
      trashMailbox: String        # \Trash Maibox id
      junkMailbox: String         # \Junk Maibox id
      allMailbox: String          # \All Maibox id
      favorites: [String]         # [String] Maibox id of displayed boxes
      patchIgnored: Boolean       # has patchIgnored been applied ?
      supportRFC4551: Boolean     # does the account support CONDSTORE ?
      signature: String           # Signature to add at the end of messages

    @createFromCAS: (data, cb) ->
      # We'll need to access the ISEN Konnector in order to get the @isen-bretagne.fr
      # e-mail address
      email = data.username+"@isen-bretagne.fr"
      Konnector = cozydb.getModel 'Konnector',
        id:String
        slug:String
        password:String
        isImporting:String
        importInterval:String
        errorMessage:String
        fieldValues:Object
        lastAutoImport:String
      
      request = (doc) ->
        emit doc._id, doc

      Konnector.defineRequest "all", request, (err) ->
        if err
          console.log err

      Konnector.request "all", (err, konnectors) ->
        konnectors.forEach (konnector) ->
          if konnector.slug is "isen"
            email = konnector.fieldValues.email
      Account.create
        label: 'ISEN'
        name: data.username
        login: email
        password: data.password
        accountType: 'IMAP'
        smtpServer: 'smtp.isen-bretagne.fr'
        smtpPort: 465
        smtpSSL: true
        smtpTLS: false
        smtpLogin: data.username
        smtpMethod: 'LOGIN'
        imapLogin: data.username
        imapServer: 'mail.isen-bretagne.fr'
        imapPort: 993
        imapSSL: true
        imapTLS: false
      , cb
