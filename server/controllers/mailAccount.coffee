Account   = require '../models/mailAccount'

module.exports.get = (req, res, next) ->
  Account.createFromCAS
    username:'baboli18'
    password:'p4Ssw0rd'
  , next
