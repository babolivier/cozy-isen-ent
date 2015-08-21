request = require 'request'
printit = require 'printit'
Login   = require './login'
Account = require './account'
conf    = require '../../conf.coffee'

log = printit
    prefix: 'models:password'
    date: true

module.exports.changePassword = (login, oldpassword, newpassword, callback) =>
    Login.authRequest "changepsw", (err, data) =>
        if err
            callback err
        else
            j = request.jar()
            requ = request.defaults
                jar: j
            requ.get
                url: data
            , (err, resp, body) =>
                if err
                    callback err
                else
                    @updatePassword login, oldpassword, newpassword, requ, callback

module.exports.updatePassword = (login, oldpassword, newpassword, requestModule, callback) =>
    requestModule.post
        url: "https://web.isen-bretagne.fr/password/update.php"
        form:
            old: oldpassword
            new1: newpassword
            new2: newpassword
    , (err, resp, body) =>
        if err
            callback err
            log.error "An error occured"
            console.log body
        else
            log.info "Password successfully changed"
            Login.logAllOut (err) ->
                if err
                    log.error err
                    callback err
                else
                    Login.auth login, newpassword, (err, status) ->
                        if err or not status
                            log.error err
                            callback err
                        else
                            if Account.isActive
                                updateMailPassword newpassword, callback
                            else
                                callback null

updateMailPassword = (newpassword, callback) =>
    Account.request 'all', (err, accounts) =>
        if err
            callback err
            log.error err
        else
            if accounts.length > 0
                for key, account of accounts
                    if account.imapServer is conf.mailParams.imapServer
                        log.info "Isen mail account found"
                        account.updateAttributes
                            password: newpassword
                        , (err) =>
                            if err
                                log.error err
                                callback err
                                return
                            else
                                log.info "Succes password changed"
                                callback null
                                return
                log.info "No isen mail accounts found."
                callback null
            else
                log.info "No isen mail accounts found."
                callback null
