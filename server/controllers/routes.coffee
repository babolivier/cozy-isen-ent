authcas = require './authcas'
account = require './mailAccount'
services = require './services'
mailingList = require './mailingList'

module.exports =
    'login':
        get: authcas.check
        post: authcas.logIn

    'authUrl/:pageid':
        get: authcas.getAuthUrl

    'email':
        get: account.getemail
        post: account.exists

    'logout':
        get: authcas.logout

    'servicesList':
        get: services.getServicesList

    'defaultService':
        get: services.getDefaultService

    'mailingList':
        get: mailingList.getMailingList

    'contacts':
        get: mailingList.getContacts