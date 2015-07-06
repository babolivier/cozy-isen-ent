cozydb      = require 'cozydb'
requestRoot = require 'request'
htmlparser  = require 'htmlparser2'

module.exports = class Login extends cozydb.CozyModel
  @docType = 'CASLogin'

  @schema =
    username: String
    password: String
    tgc: Object
    jsessionid: Object
