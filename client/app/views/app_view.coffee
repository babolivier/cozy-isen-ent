BaseView = require '../lib/base_view'
Utils = require '../lib/utils'

module.exports = class AppView extends BaseView

    el: 'body.application'
    template: require('./templates/home')

    events: =>
        'submit'     : @loginCAS

    renderIfNotLoggedIn: =>
        $.ajax
            url: 'login'
            method: 'GET'
            dataType: 'json'
            success: (data) =>
                if data.isLoggedIn
                    @goToDefaultService()
                else
                    @render()

    loginCAS: =>
        $('#status').html 'En cours'
        $.ajax
            url: 'login'
            method: 'POST'
            data:
                username: $('input#username').val()
                password: $('input#password').val()
            dataType: 'json'
            success: (data) =>
                if data.status
                    $('input#username').attr("readonly", "")
                    $('input#password').attr("readonly", "")

                    @buildOperationTodoList()
                    if @operations.length > 0
                        $('#ImportingStatus').css('display', 'block')

                        @currentOperation = 0
                        globalTimer = setInterval ->
                            @current

                        if $('#mail').prop('checked') is true
                            Utils.importMailAccount
                        if $('#contact').prop('checked') is true
                            @setOperationName "Importation des contacts"
                            @setStatusText "Etape 1/2: Récupération des contacts depuis le serveur..."
                            @setDetails ""

                            importStatus = Utils.importContacts
                            if importStatus.status is true
                                @setStatusText "Etape 2/2: Enregistrement des contacts dans votre cozy..."
                                lastStatus = Utils.getImportContactStatus
                                timer = setInterval ->
                                    status = Utils.getImportContactStatus
                                    if status.done > lastStatus.done
                                        lastStatus = status
                                        details =
                                        status.done + " contact(s) importés sur " + status.total + "."
                                        details += "<br>" + status.succes + "contact(s) crée(s)." if status.succes isnt 0
                                        details += "<br>" + status.modified + "contact(s) modifié(s)." if status.modified isnt 0
                                        details += "<br>" + status.notmodified + "contact(s) non modifié(s)." if status.notmodified isnt 0
                                        details += "<br>" + status.error + "contact(s) n'ont pu être importé(s)." if status.error isnt 0

                                        @setDetails details

                                        if status.done is status.total
                                            @setStatusText.html "Importation des contacts terminés."
                                            clearTimeout timer
                                , 200
                            else
                                @setDetails "Une erreur est survenue: " + importStatus.err
                    else
                        @goToDefaultService()
                else
                    $('#status').html 'Erreur'
            error: =>
                $('#status').html 'Erreur HTTP'

    goToDefaultService: =>
        $.ajax
            type: "GET"
            dataType: "text"
            async: false
            url: 'defaultService'
            success: (data) ->
                window.location = "#" + data

    buildOperationTodoList: =>
        @operations = new Array
        if $('#mail').prop('checked') is true
            @operations.push
                functionToCall: @importMailAccount
                terminated: false
        if $('#contact').prop('checked') is true
            @operations.push
                functionToCall: @importContacts
                terminated: false

    setOperationName: (operationName) =>
        $('#OperationName').html operationName

    setStatusText: (statusText) =>
        $('#statusText').html statusText

    setProgress: (progress) =>
        $('#progress').width progress + "%"

    setDetails: (details) =>
        $('#details').html details