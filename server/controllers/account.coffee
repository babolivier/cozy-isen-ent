Account = require '../models/account.coffee'
conf    = require '../../conf.coffee'
printit = require 'printit'

log = printit
    prefix: 'controllers:account'
    date: true

# Check if the e-mail feature is enabled in the configuration file
module.exports.isActive = (req, res, next) ->
    if Account.isActive()
        res.status(200).json active: true
    else
        res.status(418).json active: false

module.exports.create = (req, res, next) ->
    Account.loadThenCreate req.body, (err, created) ->
        if err
            log.error err
            console.error err
            res.status(500).json error: err
        else if created
            res.status(200).json created: created
        else
            res.status(304).json created: created
