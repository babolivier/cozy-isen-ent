cozydb = require 'cozydb'
VCardParser = require 'cozy-vcard'
conf   = require('../../conf.coffee').contactParams
notif  = require "./notif.coffee"

class DataPoint extends cozydb.Model
    @schema:
        name: String
        value: cozydb.NoSchema
        type: String


module.exports = class Contact extends cozydb.CozyModel
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

    @createFromVCard: (vcfString) =>
        vparser = new VCardParser vcfString.replace(/EMAIL:/g, "EMAIL;" + conf.defaultEmailTag + ":")

        vcf = new Array

        for contact in vparser.contacts
            c = new Object
            c.fn = contact.fn if contact.fn
            c.n = contact.n if contact.n
            c.datapoints = contact.datapoints if contact.datapoints
            c.tags = conf.tag
            vcf.push c

        #console.log @oldContacts
        ####

        @total = vcf.length

        for contact in vcf
            do (contact) =>
                for dt in contact.datapoints
                    if dt.name is "email" and @oldContacts[dt.value]
                        @nonmodifies.push contact.fn
                    else
                        Contact.create contact, (err, contactCree) =>
                            if err
                                @error.push err
                            else
                                @succes.push contactCree.fn
                    @done++
                    @endImport() if @done is @total
        ####

    @initImporter: (callback) =>
        @done = 0
        @total = 0
        @nonmodifies = new Array
        @error = new Array
        @succes = new Array
        @oldContacts = new Array
        @request "all", {}, (err, contacts) =>
            if err
                callback err
            else
                for contact in contacts
                    if contact.tags and contact.tags.indexOf(conf.tag[0]) != -1#que le 1er tag, a voir si il y en a plusieurs
                        for dp in contact.datapoints
                            if dp.name is "email"
                                @oldContacts[dp.value] = contact
                callback null

    @endImport: =>
        notif.createTemporary
            text: "Import des contacts ISEN terminé. " + @succes.length + " contacts importés sur " + @total + "."
        , (err)->
            console.log err if err

    @getImportStatus: =>
        resp =
            done: @done
            total: @total
            nonmodifies: @nonmodifies.length
            error: @error.length
            succes: @succes.length
        return resp