Account = require '../models/account.coffee'
conf    = require '../../conf.coffee'
printit = require 'printit'

log = printit
    prefix: 'ent-isen'
    date: true
                
module.exports.exists = (req, res, next) ->
    Account.exists (err, found) ->
        if err
            res.send err
            log.error err
        else
            res.send exists: found
            
module.exports.create = (req, res, next) ->
    Account.loadThenCreate req.body, (err, created) ->
        return next err if err
        res.account = created
        res.send created