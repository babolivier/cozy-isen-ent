log = require('../utils/logging')(prefix: 'imap:oauth')

xOAuthCache = {}

# This file handle the generation of config for node-imap and nodemailer
# it also handles xoauthgenerators as singletons by account
# to prevent race between imap & smtp in creating access tokens

# create a nodemailer config for this account
module.exports.makeSMTPConfig = (account) ->
    options =
        port: account.smtpPort
        host: account.smtpServer
        secure: account.smtpSSL
        ignoreTLS: not account.smtpTLS
        tls: rejectUnauthorized: false

    if account.smtpMethod? and account.smtpMethod isnt 'NONE'
        options.authMethod = account.smtpMethod

    options.auth =
        user: account.smtpLogin or account.login
        pass: account.smtpPassword or account.password

    return options


# create a node-imap config for this account
module.exports.makeIMAPConfig = (account, callback) ->
    callback null,
        user       : account.imapLogin or account.login
        password   : account.password
        host       : account.imapServer
        port       : parseInt account.imapPort
        tls        : not account.imapSSL? or account.imapSSL
        tlsOptions : rejectUnauthorized : false
