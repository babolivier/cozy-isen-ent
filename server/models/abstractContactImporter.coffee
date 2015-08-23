cozydb      = require 'cozydb'
VCardParser = require 'cozy-vcard'
request     = require 'request'
conf        = require('../../conf')
notif       = require "./notif"
Login       = require './login'
printit     = require 'printit'

log = printit
    prefix: 'models:abstractContactImporter'
    date: true

class DataPoint extends cozydb.Model
    @schema:
        name: String
        value: cozydb.NoSchema
        type: String

###
AbstractContactImporter: an abstract class for importing contacts.
###

module.exports = class AbstractContactImporter extends cozydb.CozyModel
    @docType: 'contact'
    @schema:
        id            : String
        fn            : String
        n             : String
        org           : String
        title         : String
        department    : String
        bday          : String
        nickname      : String
        url           : String
        revision      : Date
        datapoints    : [DataPoint]
        note          : String
        tags          : [String]
        _attachments  : Object

    ###
    Name: isActive
    Role: Permit to know if importing contact is active. This method must be redefined.
    Args: void
    Rtrn: void
    ###
    isActive: =>
        null

    ###
    Name: initImporter
    Role: Prepare the object for contacts importation. (Initializes variables)
    Args:
        tag: a string used to find contacts that might be already imported.
        contactType: a string used to describe contact's type. (used in notification message)
        callback(err): callback function. Called with err if an error occured, null otherwise.
    Rtrn:
    ###
    initImporter: (tag, contactType, callback) =>
        @contactType = contactType #String: contact type used in notification.
        @done = 0 #Int:  Contact treated.
        @total = 0 #Int: Contacts to be treated.
        @notmodified = new Array #Array: Not modified contacts.
        @modified = new Array #Array: Updated contacts.
        @error = new Array #Array: Contacts that can't be treat because of an error.
        @succes = new Array #Array: Created contacts.
        @oldContacts = new Array #Array: Contacts that are alreadyin database, and which could be sources of duplicates.

        #Getting old contacts from database that could create duplicates.
        AbstractContactImporter.request "all", {}, (err, contacts) =>
            if err
                callback err
            else
                for contact in contacts
                    if contact.tags and contact.tags.indexOf(tag) != -1 #Only first tag is used ofr the moment
                        for dp in contact.datapoints
                            if dp.name is "email"
                                @oldContacts[dp.value] = contact #Using email as array index/key.
                callback null

    ###
    Name: endImport
    Role: Emmit ending notification
    Args: void
    Rtrn: void
    ###
    endImport: =>
        traite = @notmodified.length + @modified.length + @succes.length
        notif.createTemporary
            text: "Import des contacts " + @contactType + " terminé. " + traite + " contacts traités avec succés sur " + @total + "."
        , (err)->
            log.error err if err

    ###
    Name: getImportStatus
    Role: Obtain import status.
    Args: void
    Rtrn: An Array describing import status.
    ###
    getImportStatus: =>
        resp =
            done: @done
            total: @total
            notmodified: @notmodified.length
            modified: @modified.length
            error: @error.length
            succes: @succes.length