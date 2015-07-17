authcas = require './authcas'
account = require './mailAccount'
services = require './services'

module.exports =
    'login':
        get: authcas.check
        post: authcas.logIn

    'authUrl/:pageid':
        get: authcas.getAuthUrl

    'createAccount':
        get: account.get

    'logout':
        get: authcas.logout

    'servicesList':
        get: services.getServicesList

    'defaultService':
        get: services.getDefaultService