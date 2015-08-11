login       = require './login'
account     = require './account'
services    = require './services'
contacts    = require './contacts'

module.exports =
    'login':
        get: login.check
        post: login.logIn

    'authUrl/:pageid':
        get: login.getAuthUrl

    'email':
        get: account.isActive
        put: account.create

    'logout':
        get: login.logout

    'servicesList':
        get: services.getServicesList

    'defaultService':
        get: services.getDefaultService

    'contacts':
        get: contacts.getContacts

    'isContactsActive':
        get: contacts.isActive

    'contactImportStatus':
        get: contacts.getImportStatus