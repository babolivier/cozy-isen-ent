Account = require '../models/mailAccount'
printit = require 'printit'

log = printit
    prefix: 'ent-isen'
    date: true
    
module.exports.getemail = (req, res, next) ->
    Account.getMailAddress (err, email) ->
        if err
            res.send err
            log.error err
        else
            if email
                res.send email
            else
                res.send ''
                
module.exports.exists = (req, res, next) ->
    Account.exists (err, found) ->
        if err
            res.send err
            log.error err
        else
            res.send exists: found