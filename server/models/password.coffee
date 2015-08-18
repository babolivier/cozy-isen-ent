request     = require 'request'
printit = require 'printit'
Login       = require './login'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports = class Password
    changePassword: (login, oldpassword, newpassword, callback) =>
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

    updatePassword: (login, oldpassword, newpassword, requestModule, callback) =>
        requestModule.post
            url: "https://web.isen-bretagne.fr/password/update.php"
            form:
                old: oldpassword
                new1: newpassword
                new2: newpassword
        , (err, resp, body) =>
            if err
                callback err
                console.log "erreur"
                console.log body
            else
                console.log "succes"
                Login.logAllOut (err) ->
                    if error
                        log.error err
                        callback err
                    else
                        Login.auth login, newpassword, (err, status) ->
                            if err or not status
                                log.error err
                                callback err
                            else
                                callback null