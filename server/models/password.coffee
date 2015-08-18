request     = require 'request'
Login       = require './login'

module.exports = class Password
    changePassword: (login, newpassword, callback) =>
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
                        @updatePassword login, newpassword, requ, callback

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
                console.log "succes"
                console.log body
            else
                callback null
                console.log "erreur"
                console.log body