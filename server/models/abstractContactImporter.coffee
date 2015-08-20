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

    isActive: =>
        null

    initImporter: (tag, contactType, callback) =>
        @contactType = contactType
        @done = 0
        @total = 0
        @notmodified = new Array
        @modified = new Array
        @error = new Array
        @succes = new Array
        @oldContacts = new Array
        AbstractContactImporter.request "all", {}, (err, contacts) =>
            if err
                callback err
            else
                for contact in contacts
                    if contact.tags and contact.tags.indexOf(tag) != -1#que le 1er tag, a voir si il y en a plusieurs
                        for dp in contact.datapoints
                            if dp.name is "email"
                                @oldContacts[dp.value] = contact
                callback null

    endImport: =>
        traite = @notmodified.length + @modified.length + @succes.length
        notif.createTemporary
            text: "Import des contacts " + @contactType + " terminé. " + traite + " contacts traités avec succés sur " + @total + "."
        , (err)->
            log.error err if err

    getImportStatus: =>
        resp =
            done: @done
            total: @total
            notmodified: @notmodified.length
            modified: @modified.length
            error: @error.length
            succes: @succes.length