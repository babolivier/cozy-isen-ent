request = require 'request'
printit = require 'printit'
Login   = require './login'
Account = require './account'
conf    = require '../../conf.coffee'

log = printit
    prefix: 'models:password'
    date: true

###
Name: changePassword
Role: authentificate with password changing service
Args:
    oldpassword:
    newpassword:
    callback(err):
Rtrn: void
###
module.exports.changePassword = (oldpassword, newpassword, callback) =>
    Login.authRequest "changepsw", (err, data) =>
        if err
            callback err
            log.error err
        else
            j = request.jar()
            requ = request.defaults
                jar: j
            requ.get
                url: data
            , (err, resp, body) =>
                if err
                    callback err
                    log.error err
                else
                    @updatePassword oldpassword, newpassword, requ, callback

###
Name: updatePassword
Role: upadte password with/on password service.
Args:
    login:
    oldpassword:
    newpassword:
    requestModule:
    callback:
Rtrn: void
###
module.exports.updatePassword = (oldpassword, newpassword, requestModule, callback) =>
    Login.request 'all', (err, results) =>
        #log si err à mettre
        login = results[results.length-1].username
        if results[results.length-1].password != oldpassword
            err = "Ancien mot de passe incorect."
            log.error err
            callback err
        else
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
                    log.error err
                    console.log body
                else
                    log.info "Password successfully changed"
                    log.info "0"
                    Login.logAllOut (err) ->
                        if err
                            log.error err
                            callback err
                        else
                            log.info "1"
                            Login.auth login, newpassword, (err, status) ->
                                log.info "2"
                                if err or not status
                                    log.info "3"
                                    log.error err
                                    callback err
                                else
                                    log.info "5"
                                    if Account.isActive
                                        log.info "6"
                                        updateMailPassword newpassword, callback
                                    else
                                        log.info "7"
                                        callback null

###
Name: updateMailPassword
Role: updateMailPassword stored into database
Args:
    newpassword:
    callback:
Rtrn: void
###
updateMailPassword = (newpassword, callback) =>
    log.info "8"
    Account.request 'all', (err, accounts) =>
        log.info "9"
        if err
            log.info "10"
            callback err
            log.error err
        else
            log.info "11"
            if accounts.length > 0
                log.info "12"
                callbackCalled = false
                for key, account of accounts
                    log.info "13"
                    if account.imapServer is conf.mailParams.imapServer
                        log.info "14"
                        log.info "Isen mail account found"
                        account.updateAttributes
                            password: newpassword
                        , (err) =>
                            log.info "15"
                            if err
                                log.info "16"
                                log.error err
                                log.info "17"
                                if callbackCalled is false
                                    log.info "18"
                                    callback err
                            else
                                log.info "19"
                                log.info "E-mail account's password successfully changed"
                                found = true
                                log.info "20"
                                if callbackCalled is false
                                    log.info "21"
                                    callback null
                            callbackCalled = true
                            log.info "22"
                    if key+1 == accounts.length and callbackCalled is false
                        log.info "23"
                        log.info "No isen mail account found."
                        callback null
            else
                log.info "24"
                log.info "No isen mail account found."
                callback null