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
        $('#authStatus').html ''
        $('#submitButton').html '<img src="spinner-white.svg">'
        $.ajax
            url: 'login'
            method: 'POST'
            data:
                username: $('input#username').val()
                password: $('input#password').val()
            dataType: 'json'
            complete: (xhr) =>
                if xhr.status is 200
                    $('input#username').attr("readonly", "")
                    $('input#password').attr("readonly", "")

                    @saveFormData()
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
                else if xhr.status is 401
                    $('#authStatus').html 'Login/mot de passe incorrect(s).'
                    $('#submitButton').html 'Se connecter'
                else
                    $('#authStatus').html 'Erreur HTTP'
                    $('#submitButton').html 'Se connecter'
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
            functionToCall: @changepsw
            launched: false
            terminated: false

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

    showNextStepButton: (bool) =>
        if bool
            $('#nextStepButton').css('display', 'block')
            $('#nextStepButton').one 'click', =>
                @operations[@currentOperation].terminated = true
                @showNextStepButton false
        else
            $('#nextStepButton').css('display', 'none')

    saveFormData: =>
        @formData = neObject
        @formData.username = $('input#username').val()
        @formData.password = $('input#password').val()

    changepsw: =>
        @setOperationName "Changement de votre mot de passe:"
        @setStatusText "Il devrait contenir au moins 8 caractères. Les caractères spéciaux sont fortement recommandés."
        @setDetails ""
        @showProgressBar false

        form =
            """
            <form onSubmit="return false" id="authForm">
                <input type="password" id="newpassword" placeholder="Nouveau mot de passe"/><br/>
                <button type="submit" id="submitButton" class="button">Changer mon mot de passe</button>
            </form>
            <div id="authStatus"></div>
            """
        @setDetails form
        $('form').one 'submit', =>
            $('#submitButton').html '<img src="spinner-white.svg">'
            Utils.changepsw @formData.username, $('#newpassword').val(), (err) =>
                if err
                    $('#submitButton').css('display','none')
                    $('#authStatus').html 'Une erreur fatale est survenue: ' + err + '<br>Impossible de continuer.'
                else
                    $('#submitButton').css('display','none')
                    $('#authStatus').html 'done'

    importMailAccount: =>
        @setOperationName "Importation de votre compte mail ISEN"
        @setStatusText ""
        @setDetails ""
        @showProgressBar false
        Utils.isMailActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation du compte mail depuis le menu configuration de l'application."
                @showNextStepButton true
            else if active
                @setStatusText 'Importation en cours...<img id=spinner src="spinner.svg">'
                Utils.importMailAccount
                    username: $('input#username').val()
                    password: $('input#password').val()
                , (err, imported) =>
                    if err
                        @setStatusText 'Importation en cours...'
                        @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation de votre mail ISEN depuis le menu configuration de l'application."
                        @showNextStepButton true
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
        @setStatusText ""
        @setDetails ""
        @showProgressBar false
        Utils.isContactsActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation du compte mail depuis le menu configuration de l'application."
                @showNextStepButton true
            else if active
                @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur...<img id=spinner src="spinner.svg">'
                Utils.importContacts (err) =>
                    if err
                        @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur...'
                        @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation des contacts depuis le menu configuration de l'application."
                        @showNextStepButton true
                    else
                        @setStatusText 'Etape 2/2 : Enregistrement des contacts dans votre cozy...<img id=spinner src="spinner.svg">'
                        @setProgress 0
                        @showProgressBar true
                        @lastStatus = new Object
                        @lastStatus.done = 0
                        Utils.getImportContactStatus @checkStatus

                        @timer = setInterval =>
                            Utils.getImportContactStatus @checkStatus
                        ,200
            else
                @setStatusText "Cette fonctionnalité a été désactivée par l'administrateur de l'application."
                @setDetails ""
                @setProgress 100
                setTimeout =>
                    @operations[@currentOperation].terminated = true
                ,5000

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
                    @setStatusText 'Etape 2/2 : Enregistrement des contacts dans votre cozy...'
                    @setStatusText "Importation des contacts terminée."
                    clearInterval @timer

                    setTimeout =>
                        @operations[@currentOperation].terminated = true
                    ,3000