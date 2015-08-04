conf    = require '../../conf.coffee'

module.exports.getServicesList = (req, res, next) ->
    res.status(200).send conf.servicesList

module.exports.getDefaultService = (req, res, next) ->
    res.status(200).send conf.defaultService