cozydb      = require 'cozydb'
VCardParser = require 'cozy-vcard'
request     = require 'request'
conf        = require('../../conf')
notif       = require "./notif"
Login       = require './login'
printit     = require 'printit'
AbstractContactImporter = require './abstractContactImporter'

log = printit
    prefix: 'models:contact'
    date: true

class DataPoint extends cozydb.Model
    @schema:
        name: String
        value: cozydb.NoSchema
        type: String


module.exports = class Contact extends AbstractContactImporter
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
                                    log.error err
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
                @initImporter conf.contactParams.tag[0], 'administratif ISEN', (err) =>
                    if err
                        callback err
                    else
                        callback null
                        @createFromVCard body