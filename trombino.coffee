express = require 'express'
app     = express()
request = require 'request'
#require('request').debug = true
#require('request-debug')(request)
cheerio = require 'cheerio'
async   = require 'async'

app.get '/', (req, res, next) ->
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_cycles.php'
    , (err, status, body) ->
        cycles = []
        $ = cheerio.load body
        $('option').each (i, elem) ->
            if $(this).html() isnt 'Cycles'
                cycles.push name: $(this).html()
        async.mapSeries cycles, requestYears, (err, results) ->
            if err
                console.log err
                res.status(500).send err
            else
                res.send results

requestStudents = (groupe, next) ->
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_etudiants.php'
        form:
            choix_groupe: groupe.name
            nombre_colonnes: 5
    , (err, status, body) ->
        if err
            next err
        else
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
            groupe.students = students
            next null, groupe

requestGroups = (annee, next) ->
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_groupes.php'
        form:
            choix_annee: annee.name
            choix_cycle: annee.cycle
            statut: 'etudiant'
    , (err, status, body) ->
        if err
            next err
        else
            groupes = []
            $ = cheerio.load body
            $('option').each (i, elem) ->
                if $(this).html() isnt 'Groupes'
                    groupes.push name: $(this).html()
            annee.groupes = groupes
            async.mapSeries annee.groupes, requestStudents, (err, results) ->
                if err
                    next err
                else
                    next null, results

requestYears = (cycle, next) ->
    request.post
        url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_annees.php'
        form:
            choix_cycle: cycle.name
    , (err, status, body) ->
        annees = []
        $ = cheerio.load body
        $('option').each (i, elem) ->
            if $(this).html() isnt 'Ann&#xE9;es'
                annees.push name: $(this).html()
        cycle.annees = annees
        cycle.annees.cycle = cycle.name
        async.mapSeries cycle.annees, requestGroups, (err, results) ->
            if err
                next err
            else
                next null, results

app.listen 8080, ->
    console.log 'Listening'
