Account   = require '../models/mailAccount'

module.exports.get = (req, res, next) ->
  Account.createFromCAS
    username:'baboli18'
    password:'**********************'
  , next
