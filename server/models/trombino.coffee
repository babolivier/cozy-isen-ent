request = require 'request'
cheerio = require 'cheerio'
async   = require 'async'
Contact = require './abstractContactImporter'
conf    = require '../../conf'
printit = require 'printit'

log = printit
    prefix: 'models:trombino'
    date: true

###
    Class Trombino
    Scraps ISEN's trombinoscope to get students informations and import them as
    contacts in Cozy
###

module.exports = class Trombino extends Contact
    @cycle: ""

    # isActive: Indicate wether or not the import is activated in the configuration

    isActive: =>
        if conf.studentsContacts
            @params = conf.studentsParams
        conf.studentsContacts

    # getAll: Get all the trombinoscope's content
    #
    # next(err, results); results: An arranged (see @rearrange) object containing
    #                           all the students

    getAll: (next) =>
        @getCycles (err, results) =>
            if err
                next err
            else
                async.mapSeries results, @getList, (err, results) =>
                    next null, @rearrange results

    # getCycles: Get the cycles (CIR, CSI, Majeures, BTS...)
    #
    # next(err, cycles); cycles; An array containing all the cycles

    getCycles: (next) ->
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

    # getList: Get a list of years, groups and students for a given cycle
    #
    # cycle: An object, cycle.name being the cycle's name
    # next(err, results); results: The said list

    getList: (cycle, next) =>
        @cycle = cycle.name
        @requestYears (err, results) ->
            if err
                next err
            else
                next null, results

    # requestStudents: Requests and parse all the students for a given group
    #
    # groupe: The given group, as an object, with groupe.name being its name
    #       and groupe.students being the students in it
    # next(err, groupe); groupe: The modified "groupe" parameter. The students
    #       objects look like this:
    #       {
    #           name: "Brendan Abolivier"
    #           photo: "https://web.isen-bretagne.fr/trombino/img/844236.jpg"
    #           email: "brendan.abolivier@isen-bretagne.fr"
    #       }

    requestStudents: (groupe, next) ->
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
                if $('td#tdTrombi').length isnt 0
                    for img in $('img')
                        if path = img.attribs.src.match '\.\/(.+)\.(jpg|png)'
                            img.attribs.src = 'https://web.isen-bretagne.fr/trombino/'+path[1]+'.'+path[2]
                            # If you're reading this you have no life
                    $('td#tdTrombi').each (i, elem) ->
                        students.push
                            name: $(this).children('b').text()
                            photo: $(this).children('img')[0].attribs.src
                            email: $(this).children('a').text()
                    log.info 'Successfully retrieved '+students.length+' students in group '+groupe.name
                    groupe.students = students
                else
                    groupe.students = []
                    log.info 'No students retrieved from '+groupe.name
                next null, groupe

    requestGroups: (annee, next) =>
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
                log.info 'Successfully retrieved '+groupes.length+' groups from year '+annee.name
                async.mapSeries annee.groupes, @requestStudents, (err, results) ->
                    if err
                        next err
                    else
                        next null, name: annee.name, groupes: results

    requestYears: (next) =>
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
            log.info 'Successfully retrieved '+annees.length+' years from cycle '+@cycle
            async.mapSeries annees, @requestGroups, (err, results) =>
                if err
                    next err
                else
                    next null, name: @cycle, annees: results

    rearrange: (results) =>
        students = {}
        cycleName = anneeName = groupeName = ""
        for cycle in results
            cycleName = cycle.name
            for annee in cycle.annees
                anneeName = annee.name
                for groupe in annee.groupes
                    groupName = groupe.name
                    for student in groupe.students
                        if student.email
                            if students[student.email]
                                students[student.email].tags.push groupName
                            else
                                name = student.name.match /([^ ]+) (.+)/
                                students[student.email] =
                                    fn: student.name
                                    n: name[2]+';'+name[1]+';;;'
                                    datapoints: [{
                                        name: "email"
                                        value: student.email
                                        type: @params.defaultEmailTag
                                    }]
                                    tags: [@params.defaultTag, cycleName, anneeName, groupName]
        students

    startImport: (next) =>
        @getAll (err, students) =>
            if err
                next err
            else
                @initImporter @params.defaultTag, "étudiants ISEN", (err) =>
                    if err
                        next err
                    else
                        next null
                        @import students


    import: (students) =>
        @total = Object.keys(students).length
        for email, student of students
            if @oldContacts[email]
                if student.n isnt @oldContacts[email].n \
                or student.fn isnt @oldContacts[email].fn
                    oldContact = @oldContacts[email].toJSON()
                    @oldContacts[email].updateAttributes
                        fn: student.fn
                        n: student.n
                    , (err) =>
                        if err
                            @oldContacts[email].beforeUpdate = oldContact
                            @error.push err
                            log.error err
                        else
                            @modified.push student.fn
                        @done++
                        @endImport() if @done is @total
                else
                    @notmodified.push student.fn
                    @done++
                    @endImport() if @done is @total
            else
                Contact.create student, (err, contactCree) =>
                    if err
                        @error.push err
                    else
                        @succes.push contactCree.fn
                    @done++
                    @endImport() if @done is @total
