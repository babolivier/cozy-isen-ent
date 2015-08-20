request = require 'request'
#require('request').debug = true
#require('request-debug')(request)
cheerio = require 'cheerio'
async   = require 'async'
Contact = require './contact'

module.exports = class Trombino
    @cycle: ""

    @getAll: (next) =>
        @getCycles (err, results) =>
            if err
                next err
            else
                async.mapSeries results, @getList, (err, results) ->
                    next null, results

    @getCycles: (next) ->
        request.post
            url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_cycles.php'
        , (err, status, body) ->
            if err
                next err
            else
                cycles = []
                $ = cheerio.load body
                $('option').each (i, elem) ->
                    if $(this).html() isnt 'Cycles'
                        cycles.push name: $(this).text()
                next null, cycles

    @getList: (cycle, next) =>
        @cycle = cycle.name
        @requestYears @cycle, (err, results) ->
            if err
                next err
            else
                next null, results

    @requestStudents: (groupe, next) ->
        console.log groupe
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
                        name: $(this).children('b').text()
                        photo: $(this).children('img')[0].attribs.src
                        email: $(this).children('a').text()
                console.log 'Registered '+students.length+' students'
                groupe.students = students
                next null, groupe

    @requestGroups: (annee, next) =>
        console.log "Année"
        console.log annee
        request.post
            url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_groupes.php'
            form:
                choix_annee: annee.name
                choix_cycle: @cycle
                statut: 'etudiant'
        , (err, status, body) =>
            if err
                next err
            else
                groupes = []
                $ = cheerio.load body
                $('option').each (i, elem) ->
                    if $(this).html() isnt 'Groupes'
                        groupes.push name: $(this).text()
                annee.groupes = groupes
                async.mapSeries annee.groupes, @requestStudents, (err, results) ->
                    if err
                        next err
                    else
                        next null, name: annee.name, groupes: results

    @requestYears: (cycle, next) =>
        console.log "Cycle"
        console.log @cycle
        request.post
            url: 'https://web.isen-bretagne.fr/trombino/fonctions/ajax/lister_annees.php'
            form:
                choix_cycle: @cycle
        , (err, status, body) =>
            annees = []
            $ = cheerio.load body
            $('option').each (i, elem) ->
                if $(this).text() isnt 'Années'
                    annees.push name: $(this).text()
            async.mapSeries annees, @requestGroups, (err, results) =>
                if err
                    next err
                else
                    next null, name: @cycle, annees: results

    @rearrange: (results) =>
        students = {}
        cycleName = anneeName = groupeName = ""
        for cycle in results
            cycleName = cycle.name
            for annee in cycle.annees
                anneeName = annee.name
                for groupe in annee.groupes
                    groupName = groupe.name
                    for student in groupe.students
                        if students[student.email]
                            students[student.email].groupes.push groupName
                        else
                            students[student.email] =
                                nom: student.name
                                photo: student.photo
                                cycle: cycleName
                                annee: anneeName
                                groupes: [groupName]
        students
