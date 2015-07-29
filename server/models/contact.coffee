cozydb = require 'cozydb'
VCardParser = require 'cozy-vcard'
conf   = require('../../conf.coffee').contactParams

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

    @createFromVCard: (vcfString) ->
        vparser = new VCardParser vcfString.replace(/EMAIL:/g, "EMAIL;" + conf.defaultEmailTag + ":")

        vcf = new Array

        for contact in vparser.contacts
            c = new Object
            c.fn = contact.fn if contact.fn
            c.n = contact.n if contact.n
            c.datapoints = contact.datapoints if contact.datapoints
            c.tags = conf.tag
            vcf.push c
        ###
        for contact in vcf
            do (contact) ->
                Contact.create contact, (err, contactCree) ->
                    if err
                        console.log err
                    else
                        console.log "Contact " + contactCree.fn + " has been saved."
        ###
        console.log 1
        return vcf