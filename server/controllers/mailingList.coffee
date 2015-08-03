printit = require 'printit'
request = require 'request'
conf    = require('../../conf.coffee').contactParams
Login   = require '../models/login'
Contact = require '../models/contact'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.getContacts = (req, res, next) ->
    if conf.clientServiceUrlForLogin
        Login.authRequest conf.clientServiceUrlForLogin, (err, data) =>
            if err
                log.error err
                res.json
                    error: err
            else
                j = request.jar()
                requ = request.defaults
                	jar: j
                requ.get
                    url: data
                , (err, resp, body) ->
                    if err
                        res.json
                            error: err
                    else
                        ImportFromVCard requ, res
    else
        ImportFromVCard request, res

module.exports.getImportStatus = (req, res, next) ->
    res.json  Contact.getImportStatus()

ImportFromVCard = (requestModule, res) ->
    requestModule.post
        url: conf.vCardUrl
        form:
            conf.vCardPostData
    , (err, resp, body) ->
        if err
            res.json
                error: err
        else
            Contact.initImporter (err) ->
                if err
                    res.json
                        error: err
                else
                    res.json
                        status: "ok"
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
                    Contact.createFromVCard body