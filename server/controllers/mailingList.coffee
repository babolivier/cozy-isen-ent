printit = require 'printit'
request = require 'request'
cheerio = require 'cheerio'
conf    = require '../../conf.coffee'
Login   = require '../models/login'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.getMailingList = (req, res, next) ->
    Login.authRequest "mailingList", (err, data) =>
        if err
            log.error err
            res.send err
        else
            mail = new Array

            j = request.jar()
            req = request.defaults
            	jar: j
            req.get
                url: data
            , (err, resp, body) ->
                $ = cheerio.load body
                $("#list_name").each ->
                    str = $(this).text()

                    emailAddr = str + "@" + conf.mailParams.domain
                    str = str.replace(new RegExp("_","g")," ").toLowerCase()
                    emailLabel = str.charAt(0).toUpperCase() + str.slice(1)

                    mail.push
                        label: emailLabel
                        mail: emailAddr
                res.send mail

module.exports.getContacts = (req, res, next) ->
    Login.authRequest "horde", (err, data) =>
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
                ####
                req.post
                    url: 'https://web.isen-bretagne.fr/horde/turba/data.php'
                    form:
                        exportID: 102
                        source: "ldap-ISEN"
                        actionID: "export"
                , (err, resp, body) ->
                    res.send body
                ###
                req.post
                    url: 'https://web.isen-bretagne.fr/horde/dimp/dimple.php/ContactAutoCompleter/input=to'
                    form:
                        to: "a"
                        _: ""
                , (err, resp, body) ->
                    res.send body.replace(/<(?:.|\n)*?>/gm, '').replace(new RegExp('&gt;','g'),'<br />').replace(new RegExp('&lt;','g'),' - ')
                ###