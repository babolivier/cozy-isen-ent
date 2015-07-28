printit = require 'printit'
request = require 'request'
cheerio = require 'cheerio'
VCardParser = require 'cozy-vcard'
conf    = require('../../conf.coffee').contactParams
Login   = require '../models/login'
Contact = require '../models/contact'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.getContacts = (req, res, next) ->
    Login.authRequest conf.clientServiceUrlForLogin, (err, data) =>#service login
        if err
            log.error err
            res.send err
        else
            j = request.jar()
            req = request.defaults
            	jar: j
            req.get
                url: data
            , (err, resp, body) ->
                req.post
                    url: conf.vCardUrl#url for vcard
                    form:
                        conf.vCardPostData
                , (err, resp, body) ->
                    vparser = new VCardParser body.replace(/EMAIL:/g, "EMAIL;" + conf.defaultEmailTag + ":")#tag email si non spécifié

                    vcf = new Array

                    for contact in vparser.contacts
                        c = new Object
                        c.fn = contact.fn if contact.fn
                        c.n = contact.n if contact.n
                        c.datapoints = contact.datapoints if contact.datapoints
                        c.tags = conf.tag#tag du contact
                        vcf.push c

                    for contact in vcf
                        do (contact) ->
                            Contact.create contact, (err, contactCree) ->
                                if err
                                    console.log err
                                else
                                    console.log "Contact " + contactCree.fn + " has been saved."

                    res.send vcf

module.exports.testImport = (req ,res, next) ->
    vcfString =
        """
        BEGIN:VCARD
        VERSION:2.1
        FN:yann le ru
        EMAIL:yann.le-ru@isen-bretagne.fr
        N:ru;yann le;;;
        END:VCARD
        BEGIN:VCARD
        VERSION:2.1
        FN:didier le foll
        EMAIL:didier.le-foll@isen-bretagne.fr
        N:foll;didier le;;;
        END:VCARD
        """

    vparser = new VCardParser vcfString.replace(/EMAIL:/g, "EMAIL;ISEN:")

    vcf = new Array

    for contact in vparser.contacts
        c = new Object
        c.fn = contact.fn if contact.fn
        c.n = contact.n if contact.n
        c.datapoints = contact.datapoints if contact.datapoints
        c.tags = ["ISEN"]
        vcf.push c

    for contact in vcf
        do (contact) ->
            Contact.create contact, (err, contactCree) ->
                if err
                    console.log err
                else
                    console.log "Le contact " + contactCree.fn + " à bien été enregistré."

    res.send vcf