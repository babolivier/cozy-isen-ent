printit = require 'printit'
request = require 'request'
cheerio = require 'cheerio'
conf    = require '../../conf.coffee'
Login   = require '../models/login'
Contact = require '../models/contact'

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
                    #res.send body

                    tab = body.replace(/\r/g,"").split("\n")

                    vcf = new Array

                    for i in [2..tab.length] by 6
                        vcf.push
                            fn: tab[i].substring(3)
                            n: tab[i+2].substring(2)
                            datapoints: [{"name":"email","type":"ISEN","value":tab[i+1].substring(6)}]
                            tags: ["ISEN"]
                    #
                    for contact in vcf
                        do (contact) ->
                            Contact.create contact, (err, contactCree) ->
                                if err
                                    console.log err
                                else
                                    console.log "Le contact " + contactCree.fn + " à bien été enregistré."
                    #
                    res.json vcf
                ###
                req.post
                    url: 'https://web.isen-bretagne.fr/horde/dimp/dimple.php/ContactAutoCompleter/input=to'
                    form:
                        to: "a"
                        _: ""
                , (err, resp, body) ->
                    res.send body.replace(/<(?:.|\n)*?>/gm, '').replace(new RegExp('&gt;','g'),'<br />').replace(new RegExp('&lt;','g'),' - ')
                ###
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
    tab = vcfString.split("\n")

    vcf = new Array

    for i in [2..tab.length] by 6
        vcf.push
            fn: tab[i].substring(3)
            n: tab[i+2].substring(2)
            datapoints: [{"name":"email","type":"ISEN","value":tab[i+1].substring(6)}]
            tags: ["ISEN"]

    for contact in vcf
        do (contact) ->
            Contact.create contact, (err, contactCree) ->
                if err
                    console.log err
                else
                    console.log "Le contact " + contactCree.fn + " à bien été enregistré."
    res.send vcf