printit = require 'printit'
Password = require '../models/password'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.changePassword = (req, res, next) ->
    Password.changePassword req.body.login, req.body.oldpassword, req.body.newpassword, (err) ->
        if err
            log.error err
            console.error err
            res.status(500).json error: err
        else
            res.status(200).json status: true