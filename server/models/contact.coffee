cozydb      = require 'cozydb'
VCardParser = require 'cozy-vcard'
request     = require 'request'
conf        = require('../../conf')
notif       = require "./notif"
Login       = require './login'

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

    @isActive: =>
        if conf.contact
            return true
        else
            return false

    @createFromVCard: (vcfString) =>
        vparser = new VCardParser vcfString.replace(/EMAIL:/g, "EMAIL;" + conf.contactParams.defaultEmailTag + ":")

        vcf = new Array

        for contact in vparser.contacts
            c = new Object
            c.fn = contact.fn if contact.fn
            c.n = contact.n if contact.n
            c.datapoints = contact.datapoints if contact.datapoints
            c.tags = conf.contactParams.tag
            vcf.push c

        ####

        @total = vcf.length

        for contact in vcf
            do (contact) =>
                for dt in contact.datapoints
                    if dt.name is "email" and @oldContacts[dt.value]
                        if contact.n isnt @oldContacts[dt.value].n \
                        or contact.fn isnt @oldContacts[dt.value].fn
                            oldContact = @oldContacts[dt.value].toJSON()
                            @oldContacts[dt.value].updateAttributes
                                fn: contact.fn
                                n: contact.n
                            , (err) =>
                                if err
                                    @oldContacts[dt.value].beforeUpdate = oldContact
                                    @error.push err
                                    console.log err
                                else
                                    @modified.push contact.fn
                                @done++
                                @endImport() if @done is @total
                        else
                            @notmodified.push contact.fn
                            @done++
                            @endImport() if @done is @total
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
        @notmodified = new Array
        @modified = new Array
        @error = new Array
        @succes = new Array
        @oldContacts = new Array
        @request "all", {}, (err, contacts) =>
            if err
                callback err
            else
                for contact in contacts
                    if contact.tags and contact.tags.indexOf(conf.contactParams.tag[0]) != -1#que le 1er tag, a voir si il y en a plusieurs
                        for dp in contact.datapoints
                            if dp.name is "email"
                                @oldContacts[dp.value] = contact
                callback null

    @endImport: =>
        traite = @notmodified.length + @modified.length + @succes.length
        notif.createTemporary
            text: "Import des contacts ISEN terminé. " + traite + " contacts traités avec succées sur " + @total + "."
        , (err)->
            console.log err if err

    @getImportStatus: =>
        resp =
            done: @done
            total: @total
            notmodified: @notmodified.length
            modified: @modified.length
            error: @error.length
            succes: @succes.length

    @retrieveContacts: (callback) =>
        if conf.contactParams.clientServiceUrlForLogin
            Login.authRequest conf.contactParams.clientServiceUrlForLogin, (err, data) =>
                if err
                    callback err
                else
                    j = request.jar()
                    requ = request.defaults
                    	jar: j
                    requ.get
                        url: data
                    , (err, resp, body) =>
                        if err
                            callback err
                        else
                            @ImportFromVCard requ, callback
        else
            @ImportFromVCard request, callback

    @ImportFromVCard: (requestModule, callback) =>
        requestModule.post
            url: conf.contactParams.vCardUrl
            form:
                conf.contactParams.vCardPostData
        , (err, resp, body) =>
            if err
                callback err
            else
                @initImporter (err) =>
                    if err
                        callback err
                    else
                        callback null
                        ###
                        body =
                        """
                        BEGIN:VCARD
                        VERSION:2.1
                        FN:aide-orientation
                        EMAIL:aide-orientation@isen-bretagne.fr
                        N:aide-orientation;;;;
                        END:VCARD
                        BEGIN:VCARD
                        VERSION:2.1
                        FN:Alain
                        EMAIL:alain.bravaix@isen-bretagne.fr
                        N:Alain;;;;
                        END:VCARD
                        BEGIN:VCARD
                        VERSION:2.1
                        FN:gaga
                        EMAIL:gaga.gigi@isen-bretagne.fr
                        N:gaga;;;;
                        END:VCARD
                        """
                        ###
                        @createFromVCard body