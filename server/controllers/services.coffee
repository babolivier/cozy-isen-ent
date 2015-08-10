conf    = require '../../conf.coffee'

module.exports.getServicesList = (req, res, next) ->
    slist = new Array
    for key,s of conf.servicesList
        if not s.hideClientSide
            slist.push s
    res.status(200).send slist

module.exports.getDefaultService = (req, res, next) ->
    res.status(200).send conf.defaultService