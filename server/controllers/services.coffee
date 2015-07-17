conf    = require '../../conf.coffee'

module.exports.get = (req, res, next) ->
    res.send(conf.servicesList)