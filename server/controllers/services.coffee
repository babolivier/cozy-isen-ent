servicesList    = require '../../services.json'

module.exports.get = (req, res, next) ->
  res.send(servicesList)