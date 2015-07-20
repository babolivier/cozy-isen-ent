# See documentation on https://github.com/aenario/cozydb/

cozydb  = require 'cozydb'
request = require 'request'
printit = require 'printit'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports = class Account extends cozydb.CozyModel
    @getMailAddress: (callback) =>
      # We'll need to access the ISEN Konnector in order to get the @isen-bretagne.fr
      # e-mail address
        email = null
        Konnector = cozydb.getModel 'Konnector',
            id:String
            slug:String
            password:String
            isImporting:String
            importInterval:String
            errorMessage:String
            fieldValues:Object
            lastAutoImport:String

        Konnector.request "all", (err, konnectors) =>
            if err
                callback err
            else
                i = 0;
                konnectors.forEach (konnector) =>
                    i++
                    if konnector.slug is "isen"
                        email = konnector.fieldValues.email
                    if i is konnectors.length
                        callback null, email
        
    @exists: (callback) =>
        MailAccount = cozydb.getModel 'Account',
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
        
        MailAccount.request 'all', (err, accounts) =>
            if err
                callback err
            else
                found = false
                if accounts.length > 0
                    i = 0
                    accounts.forEach (account) =>
                        i++
                        if account.imapServer is 'mail.isen-bretagne.fr'
                            found = true
                        if i is accounts.length
                            callback null, found
                else
                    callback null, found