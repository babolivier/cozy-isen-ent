login       = require './login'
account     = require './account'
services    = require './services'
contacts    = require './contacts'
password    = require './password'
trombino    = require './trombino'

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

    'contactsAdmin':
        put: contacts.startImportAdminContacts
        get: contacts.getImportStatus

    'isAdminContactsActive':
        get: contacts.isActive

    'changePassword':
        post: password.changePassword

    'trombino/status'
        get: trombino.getCurrentGroup

    'trombino/import':
        put: trombino.startImportStudentsContacts
        get: trombino.getImportStatus

    'trombino/active':
        get: trombino.isActive
