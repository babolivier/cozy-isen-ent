BaseView = require '../lib/base_view'
Utils = require '../lib/utils'
Utils = new Utils()

module.exports = class AppView extends BaseView

    el: 'body.application'
    template: require('./templates/home')

    events: =>

    renderIfNotLoggedIn: =>
        $.ajax
            url: 'login'
            method: 'GET'
            dataType: 'json'
            complete: (xhr) =>
                switch xhr.status
                    when 200 then @goToDefaultService()
                    when 401 then @render()
                    else console.error xhr.responseJSON or xhr.responseText

    afterRender: =>
        $('form').on 'submit', =>
            @loginCAS()

    loginCAS: =>
        $('#authStatus').html 'En cours'
        $.ajax
            url: 'login'
            method: 'POST'
            data:
                username: $('input#username').val()
                password: $('input#password').val()
            dataType: 'json'
            complete: (xhr) =>
                if xhr.status is 200
                    if xhr.responseJSON.status
                        $('input#username').attr("readonly", "")
                        $('input#password').attr("readonly", "")
                        $('form').off('submit')#why does not this work? :(

                        @buildOperationTodoList()
                        if @operations.length > 0

                            @currentOperation = 0
                            @globalTimer = setInterval =>
                                if @operations[@currentOperation].launched is false
                                    @operations[@currentOperation].functionToCall()
                                    @operations[@currentOperation].launched = true
                                else if @operations[@currentOperation].terminated is true
                                    if @currentOperation+1 isnt @operations.length
                                        @currentOperation++
                                    else
                                        clearInterval @globalTimer
                                        @setOperationName "Configuration terminée"
                                        @setStatusText "Les bisounours préparent l'application, redirection iminente..."
                                        @showProgressBar false
                                        @setDetails ""

                                        setTimeout =>
                                            @goToDefaultService()
                                        , 3000
                            , 500
                        else
                            @goToDefaultService()
                    else
                        $('#authStatus').html 'Erreur'
                else
                    $('#authStatus').html 'Erreur HTTP'
                    console.error xhr

    goToDefaultService: =>
        $.ajax
            type: "GET"
            dataType: "text"
            async: false
            url: 'defaultService'
            complete: (xhr) ->
                if xhr.status is 200
                    window.location = "#" + xhr.responseText
                else
                    $('#authStatus').html 'Erreur HTTP'
                    console.error xhr

    buildOperationTodoList: =>
        @operations = new Array
        @operations.push
            functionToCall: @importMailAccount
            launched: false
            terminated: false

        @operations.push
            functionToCall: @importContacts
            launched: false
            terminated: false

    setOperationName: (operationName) =>
        $('#OperationName').html operationName

    setStatusText: (statusText) =>
        $('#statusText').html statusText

    setProgress: (progress) =>
        $('#progress').width progress + "%"

    setDetails: (details) =>
        $('#details').html details

    showProgressBar: (bool) =>
        if bool
            $('#progressParent').css('display', 'block')
        else
            $('#progressParent').css('display', 'none')

    importMailAccount: =>
        Utils.isMailActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation du compte mail depuis le menu configuration de l'application."
                setTimeout =>
                    @operations[@currentOperation].terminated = true
                ,5000
            else if active
                @setOperationName "Importation de votre compte mail ISEN"
                @setStatusText "Importation en cours..."
                @setDetails ""
                @showProgressBar false
                Utils.importMailAccount
                    username: $('input#username').val()
                    password: $('input#password').val()
                , (err, imported) =>
                    if err
                        @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation de votre mail ISEN depuis le menu configuration de l'application."
                        setTimeout =>
                            @operations[@currentOperation].terminated = true
                        ,5000
                    else if imported
                        @setStatusText "Importation du compte e-mail terminée."
                        @setDetails ""
                        @setProgress 100
                        setTimeout =>
                            @operations[@currentOperation].terminated = true
                        ,5000
                    else
                        @setStatusText "Votre compte e-mail ISEN est déjà configuré dans votre Cozy."
                        @setDetails ""
                        @setProgress 100
                        setTimeout =>
                            @operations[@currentOperation].terminated = true
                        ,5000
            else
                @setStatusText "Cette fonctionnalité a été désactivée par l'administrateur de l'application."
                @setDetails ""
                @setProgress 100
                setTimeout =>
                    @operations[@currentOperation].terminated = true
                ,5000

    importContacts: =>
        @setOperationName "Importation des contacts"
        @setStatusText "Etape 1/2 : Récupération des contacts depuis le serveur..."
        @setDetails ""
        @showProgressBar false

        Utils.importContacts (err) =>
            if err
                @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation des contacts depuis le menu configuration de l'application."
                setTimeout =>
                    @operations[@currentOperation].terminated = true
                ,5000
            else
                @setStatusText "Etape 2/2 : Enregistrement des contacts dans votre cozy..."
                @setProgress 0
                @showProgressBar true
                @lastStatus = new Object
                @lastStatus.done = 0
                Utils.getImportContactStatus @checkStatus

                @timer = setInterval =>
                    Utils.getImportContactStatus @checkStatus
                ,200

    checkStatus: (err, status) =>
        if err
            console.log err
        else
            if status.done > @lastStatus.done
                @lastStatus = status
                details =
                status.done + " contact(s) importés sur " + status.total + "."
                details += "<br>" + status.succes + " contact(s) crée(s)." if status.succes isnt 0
                details += "<br>" + status.modified + " contact(s) modifié(s)." if status.modified isnt 0
                details += "<br>" + status.notmodified + " contact(s) non modifié(s)." if status.notmodified isnt 0
                details += "<br>" + status.error + " contact(s) n'ont pu être importé(s)." if status.error isnt 0

                @setDetails details
                @setProgress (100*status.done)/status.total

                if status.done is status.total
                    @setStatusText "Importation des contacts terminée."
                    clearInterval @timer

                    setTimeout =>
                        @operations[@currentOperation].terminated = true
                    ,3000