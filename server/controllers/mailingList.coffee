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
                    ImportFromVCard requ, res
    else
        ImportFromVCard request, res

ImportFromVCard = (requestModule, res) ->
    requestModule.post
        url: conf.vCardUrl
        form:
            conf.vCardPostData
    , (err, resp, body) ->
        Contact.initImporter res
        vcf = Contact.createFromVCard body
        return vcf