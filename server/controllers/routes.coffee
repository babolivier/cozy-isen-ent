authcas     = require './authcas'
account     = require './account'
services    = require './services'
contacts    = require './contacts'

module.exports =
    'login':
        get: authcas.check
        post: authcas.logIn

    'authUrl/:pageid':
        get: authcas.getAuthUrl

    'email':
        get: account.isActive
        put: account.create

    'logout':
        get: authcas.logout

    'servicesList':
        get: services.getServicesList

    'defaultService':
        get: services.getDefaultService

    'contacts':
        get: contacts.getContacts

    'contactImportStatus':
        get: contacts.getImportStatus