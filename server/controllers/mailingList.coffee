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
                res.send err
            else
                j = request.jar()
                requ = request.defaults
                	jar: j
                requ.get
                    url: data
                , (err, resp, body) ->
                    vcf = ImportFromVCard(requ)
                    #console.log vcf
                    console.log 3
                    res.send vcf
    else
        res.send(ImportFromVCard request)

ImportFromVCard = (requestModule) ->
    requestModule.post
        url: conf.vCardUrl
        form:
            conf.vCardPostData#et si pas def?
    , (err, resp, body) ->
        vcf = Contact.createFromVCard body
        #console.log vcf
        console.log 2
        return vcf