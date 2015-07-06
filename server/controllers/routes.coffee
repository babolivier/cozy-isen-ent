page    = require './page'
authcas = require './authcas'
account = require './mailAccount'

module.exports =
  'page/':
    get: page.get

  'page/:pageid':
    get: page.get

  'login':
    get: authcas.check
    post: authcas.logIn

  'authUrl/:pageid':
    get: authcas.getAuthUrl

  'createAccount':
    get: account.get

  'logout':
    get: authcas.logout
