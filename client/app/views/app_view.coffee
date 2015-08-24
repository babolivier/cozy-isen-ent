BaseView = require '../lib/base_view'
Utils = require '../lib/utils'

module.exports = class AppView extends BaseView

    el: 'body.application'
    template: require('./templates/home')

    events: =>

    beforeRender: =>
        $.ajax
            url: 'login'
            method: 'GET'
            dataType: 'json'
            complete: (xhr) =>
                switch xhr.status
                    when 200 then @goToDefaultService()
                    when 401 then
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
                                    @setStatusText "N'oubliez pas que vous pouvez relancer ces opérations depuis le menu de configuration de l'application."
                                    @showProgressBar false
                                    @setDetails ""

                                    @showNextStepButton true, true
                        , 500
                    else
                        @goToDefaultService()
                else if xhr.status is 401
                    $('#authStatus').html 'Login/mot de passe incorrect(s).'
                    $('#submitButton').html 'Se connecter'
                else
                    $('#authStatus').html 'Une erreur est survenue du côté du serveur, merci de réessayer ultérieurement.'
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
                else if xhr.status is 504
                    $('#authStatus').html "Request timed out"
                else
                    $('#authStatus').html 'Une erreur est survenue du côté du serveur, merci de réessayer ultérieurement.'
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
            functionToCall: @importAdminContacts
            launched: false
            terminated: false

        @operations.push
            functionToCall: @retrieveStudentsContacts
            launched: false
            terminated: false
        
        @operations.push
            functionToCall: @importStudentsContacts
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

    showNextStepButton: (bool, end) =>
        if bool
            if end
                $('#nextStepButton').html "Terminer"
                $('#nextStepButton').one 'click', =>
                    @goToDefaultService()
                    @showNextStepButton false
            else
                $('#nextStepButton').one 'click', =>
                    @operations[@currentOperation].terminated = true
                    @showNextStepButton false
            $('#nextStepButton').css('display', 'block')
        else
            $('#nextStepButton').css('display', 'none')

    saveFormData: =>
        @formData = new Object
        @formData.username = $('input#username').val()
        @formData.password = $('input#password').val()

    changepsw: =>
        @setOperationName "Changement de votre mot de passe"
        @setStatusText "Il devrait contenir au moins 8 caractères. Les caractères spéciaux sont fortement recommandés."
        @setDetails ""
        @showProgressBar false

        form =
            """
            <form onSubmit="return false" id="authForm">
                <input type="password" id="newpassword" placeholder="Nouveau mot de passe" required/><br/>
                <button type="submit" id="submitButton" class="button">Changer mon mot de passe</button>
            </form>
            <div id="authStatus"></div>
            """
        @setDetails form
        $('form').one 'submit', =>
            $('#submitButton').html '<img src="spinner-white.svg">'
            $('#newpassword').attr("readonly", "")
            Utils.changepsw @formData.username, @formData.password, $('#newpassword').val(), (err) =>
                if err
                    $('#submitButton').css('display','none')
                    #$('#authStatus').html 'Une erreur fatale est survenue: ' + err + '<br>Impossible de continuer.'
                    @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez changer votre mot de passe ultérieurement depuis le menu configuration de l'application."
                    @showNextStepButton true
                else
                    $('#submitButton').css('display','none')
                    @formData.password = $('#newpassword').val()
                    @setStatusText "Votre mot de passe à bien été mis à jour."
                    @setDetails ""
                    @showNextStepButton true

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
                    username: @formData.username
                    password: @formData.password
                , (err, imported) =>
                    if err
                        @setStatusText 'Importation en cours...'
                        @setDetails "Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation de votre mail ISEN depuis le menu configuration de l'application."
                        @showNextStepButton true
                    else if imported
                        @setStatusText "Importation du compte e-mail terminée."
                        @setDetails ""
                        @setProgress 100
                        @showNextStepButton true
                    else
                        @setStatusText "Votre compte e-mail ISEN est déjà configuré dans votre Cozy."
                        @setDetails ""
                        @setProgress 100
                        @showNextStepButton true
            else
                @setStatusText "Cette fonctionnalité a été désactivée par l'administrateur de l'application."
                @setDetails ""
                @setProgress 100
                @showNextStepButton true

    importAdminContacts: =>
        @setOperationName "Importation des contacts administratifs"
        @setStatusText ""
        @setDetails ""
        @showProgressBar false
        Utils.isAdminContactsActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts administratifs depuis le menu configuration de l'application."
                @showNextStepButton true
            else if active
                @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur...<img id=spinner src="spinner.svg">'
                Utils.importAdminContacts (err) =>
                    if err
                        @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur...'
                        @setDetails "Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation des contacts administratifs depuis le menu configuration de l'application."
                        @showNextStepButton true
                    else
                        @setStatusText 'Etape 2/2 : Enregistrement des contacts administratifs dans votre cozy...<img id=spinner src="spinner.svg">'
                        @setProgress 0
                        @showProgressBar true
                        @lastStatus = new Object
                        @lastStatus.done = 0
                        Utils.getAdminImportContactStatus @checkAdminContactsImportStatus

                        @timer = setInterval =>
                            Utils.getAdminImportContactStatus @checkAdminContactsImportStatus
                        ,200
            else
                @setStatusText "Cette fonctionnalité a été désactivée par l'administrateur de l'application."
                @setDetails ""
                @setProgress 100
                @showNextStepButton true

    checkAdminContactsImportStatus: (err, status) =>
        if err
            console.log err
        else
            if status.done > @lastStatus.done
                @lastStatus = status
                details =
                status.done + " contact(s) traités sur " + status.total + "."
                details += "<br>" + status.succes + " contact(s) crée(s)." if status.succes isnt 0
                details += "<br>" + status.modified + " contact(s) modifié(s)." if status.modified isnt 0
                details += "<br>" + status.notmodified + " contact(s) non modifié(s)." if status.notmodified isnt 0
                details += "<br>" + status.error + " contact(s) n'ont pu être importé(s)." if status.error isnt 0

                @setDetails details
                @setProgress (100*status.done)/status.total

                if status.done is status.total
                    @setStatusText "Importation des contacts terminée."
                    clearInterval @timer

                    @showNextStepButton true

    retrieveStudentsContacts: =>
        @setOperationName "Importation des contacts élèves"
        @setStatusText ""
        @setDetails ""
        @lastGroup = ""
        @showProgressBar false
        Utils.isStudentsContactsActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application."
                @showNextStepButton true
            else if active
                @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur. Cette opération peut prendre plusieurs minutes...<img id=spinner src="spinner.svg">'
                Utils.importStudentsContacts (err) =>
                    if err
                        @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur.'
                        @setDetails "Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application."
                        @showNextStepButton true
                    else
                        Utils.getStudentsImportRetrieveStatus @checkStudentsContactsRetrieveStatus
                        @timer = setInterval =>
                            Utils.getStudentsImportRetrieveStatus @checkStudentsContactsRetrieveStatus
                        ,500
            else
                @setStatusText "Cette fonctionnalité a été désactivée par l'administrateur de l'application."
                @setDetails ""
                @setProgress 100
                @showNextStepButton true


    importStudentsContacts: =>
        @setOperationName "Importation des contacts élèves"
        @setStatusText ""
        @setDetails ""
        @showProgressBar true
        
        @setStatusText 'Etape 2/2 : Enregistrement des contacts élèves dans votre cozy...<img id=spinner src="spinner.svg">'
        @setProgress 0
        @showProgressBar true
        @lastStatus = new Object
        @lastStatus.done = 0
        Utils.getStudentsImportContactStatus @checkStudentsContactsImportStatus

        @timer = setInterval =>
            Utils.getStudentsImportContactStatus @checkStudentsContactsImportStatus
        ,200

    checkStudentsContactsImportStatus: (err, status) =>
        if err
            console.log err
        else
            if status.done > @lastStatus.done
                @lastStatus = status
                details =
                status.done + " contact(s) traités sur " + status.total + "."
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

                    @showNextStepButton true

    checkStudentsContactsRetrieveStatus: (err, json, over) =>
        @over = false
        if err
            console.log err
            @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur.'
            @setDetails "Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application."
            @showNextStepButton true
        else
            if json.group isnt @lastGroup
                @lastGroup = json.group
                @setDetails 'En train d\'explorer le groupe '+json.group
            if over
                @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur.'
                @setStatusText "Récupération des contacts terminée."
                clearInterval @timer
                @operations[@currentOperation].terminated = true