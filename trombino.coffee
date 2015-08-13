express = require 'express'
app     = express()
request = require 'request'
#require('request').debug = true
require('request-debug')(request)
cheerio = require 'cheerio'

app.get '/annees', (req, res, next) ->
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_annees.php'
        form:
            choix_cycle: 'CIR'
    , (err, status, body) ->
        annees = []
        $ = cheerio.load body
        $('option').each (i, elem) ->
            if $(this).html() isnt 'Ann&#xE9;es'
                annees.push $(this).html()
        annees.forEach (annee) ->
            groupes = []
            request.post
                url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_groupes.php'
                form:
                    choix_annee: annee
                    choix_cycle: 'CIR'
                    statut: 'etudiant'
            (err, status, body) ->
                console.log body
                $ = cheerio.load body
                $('option').each (i, elem) ->
                    groupes.push $(this).html()
                console.log 'Année '+annee+'; Groupes :'
                console.log groupes
        res.send annees

app.get '/groupes', (req, res, next) ->
    annee = 'CIR 3'
    groupes = []
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_groupes.php'
        headers:
            'content-type': 'application/x-www-form-urlencoded'
        #form:
        #    choix_cycle: 'CIR'
        #    choix_annee: annee
        #    statut: 'etudiant'
        body: 'choix_cycle=CIR&choix_annee=CIR 3&statut=etudiant'
    (err, status, body) ->
        console.log body
        $ = cheerio.load body
        $('option').each (i, elem) ->
            groupes.push $(this).html()
        console.log 'Année '+annee+'; Groupes :'
        console.log groupes
    res.send 'working...'

app.get '/', (req, res, next) ->
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_etudiants.php'
        form:
            choix_groupe: 'CIR3 2015-2016'
            nombre_colonnes: 5
    , (err, status, body) ->
        students = []
        $ = cheerio.load body
        for img in $('img')
            if path = img.attribs.src.match '\.\/(.+)\.(jpg|png)'
                img.attribs.src = 'https://web.isen-bretagne.fr/trombino/'+path[1]+'.'+path[2]
        $('td#tdTrombi').each (i, elem) ->
            students.push
                name: $(this).children('b').html()
                photo: $(this).children('img')[0].attribs.src
                email: $(this).children('a').html()
        res.send students

app.listen 8080, ->
    console.log 'Listening'
