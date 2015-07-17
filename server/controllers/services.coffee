conf    = require '../../conf.coffee'

module.exports.getServicesList = (req, res, next) ->
    res.send(conf.servicesList)

module.exports.getDefaultService = (req, res, next) ->
    res.send(conf.defaultService)