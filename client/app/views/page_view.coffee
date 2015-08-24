BaseView  = require '../lib/base_view'
AppView   = require 'views/app_view'
Utils     = require '../lib/utils'

module.exports = class PageView extends BaseView

    el: 'body'
    template: require './templates/page'

    error: ''

    events: =>
        'click #closeError': 'hideError'
        'keydown': 'hideError'

    isOperationActive: false

    getRenderData: ->
        res =
            url: @url

    renderPage: (pageid) =>
        @pageid = pageid
        $.ajax
            type: "GET"
            dataType: "json"
            async: false
            url: 'authUrl/'+pageid
            complete: (xhr) =>
                switch xhr.status
                    when 401 then window.location = "#login"
                    when 400
                        #@error = t("unknown service")+" "+pageid
                        @error = "Unknown service "+pageid
                        @url = ""
                    when 200 then @url = xhr.responseJSON.url
                    when 504 then @error = "Request timed out"
                    else
                        @error = xhr.responseText
                        console.log xhr.responseJSON
                document.title = window.location
                @render()

    afterRender: =>
        if @error
            @showError @error
        $.ajax
            type: "GET"
            dataType: "json"
            async: false
            url: 'servicesList'
            complete: (xhr) =>
                if xhr.status is 200
                    data = xhr.responseJSON
                    ##
                    menu = new Array
                    for key, service of data
                        if menu[service.category] is undefined
                            menu[service.category] = new Array
                        menu[service.category].push service

                    for categorie, tabService of menu
                        menuList = '<li><span>' + categorie + '</span><ul>'
                        for key, service of tabService
                            idCurrentService = ""
                            if service.clientServiceUrl is @pageid
                                idCurrentService = ' id="currentService"'
                                if service.clientRedirectPage
                                    @redirectUrl = service.clientRedirectPage
                                    if service.clientRedirectTimeOut
                                        setTimeout =>
                                            $("#app").attr("src", @redirectUrl)
                                        , service.clientRedirectTimeOut
                                    else
                                        $("#app").one "load", =>
                                            $("#app").attr("src", @redirectUrl)
                            li =
                                '<li class="serviceButton"'+idCurrentService+'>
                                    <a href="#'+service.clientServiceUrl+'">
                                        <i class="'+service.clientIcon+'"></i>
                                        <span>'+service.displayName+'</span>
                                    </a>
                                </li>'
                            menuList += li
                        menuList += '</ul></li>'
                        $("#servicesMenu").append(menuList)
                else if xhr.status is 504
                    @showError "Request timed out"
                else
                    data = xhr
                    @showError data.status + " : " + data.statusText + "<br>" + data.responseText
        @bindMenuOp()

    showError: (err) =>
        $("#errorText").html err
        $("#errors").removeClass 'off-error'
        $("#errors").addClass 'on-error'

    hideError: (e)=>
        if e.type is "click" or e.keyCode is 13 or e.keyCode is 27
            $("#errors").removeClass 'on-error'
            $("#errors").addClass 'off-error'

    #### Redo onboarding operation
    bindMenuOp: =>
        that = this

        $('.paramsButton').on 'click', ->
            $('#modalBackground').css 'display', 'block'
            $('#replayOp').css 'display', 'block'

        $('#close').on 'click', ->
            if not that.isOperationActive
                $('#modalBackground').css 'display', 'none'
                $('#replayOp').css 'display', 'none'

        $('#mail').on 'click', ->
            if not that.isOperationActive
                $(this).addClass('active')
                that.enableButtons false
                that.isOperationActive = true
                that.importMailAccount()

        $('#ca').on 'click', ->
            if not that.isOperationActive
                $(this).addClass('active')
                that.enableButtons false
                that.isOperationActive = true
                that.importAdminContacts()

        $('#ce').on 'click', ->
            if not that.isOperationActive
                $(this).addClass('active')
                that.enableButtons false
                that.isOperationActive = true
                that.retrieveStudentsContacts()

        $('#pass').on 'click', ->
            if not that.isOperationActive
                $(this).addClass('active')
                that.enableButtons false
                that.isOperationActive = true
                that.changepsw()

        $('#raz').on 'click', =>
            if not that.isOperationActive
                $(this).addClass('active')
                that.enableButtons false
                window.location = '#logout'

    enableButtons: (bool) =>
        if bool
            $('#mail').removeClass('active').removeClass('inactive')
            $('#ca').removeClass('active').removeClass('inactive')
            $('#ce').removeClass('active').removeClass('inactive')
            $('#pass').removeClass('active').removeClass('inactive')
            $('#raz').removeClass('active').removeClass('inactive')
            $('#close').removeClass('closeInactive')
        else
            $('#mail').addClass('inactive')
            $('#ca').addClass('inactive')
            $('#ce').addClass('inactive')
            $('#pass').addClass('inactive')
            $('#raz').addClass('inactive')
            $('#close').addClass('closeInactive')

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

    showEndStepButton: =>
        $('#nextStepButton').one 'click', =>
            @isOperationActive = false
            @enableButtons true
            @setOperationName ""
            @setStatusText ""
            @setDetails ""
            @showProgressBar false
            $('#nextStepButton').css('display', 'none')
        $('#nextStepButton').css('display', 'block')

    changepsw: =>
        @setOperationName "Changement de votre mot de passe"
        @setStatusText "Il devrait contenir au moins 8 caractères. Les caractères spéciaux sont fortement recommandés."
        @setDetails ""
        @showProgressBar false

        form =
            """
            <form onSubmit="return false" id="authForm">
                <input type="text" id="login" placeholder="Login" required/><br/>
                <input type="password" id="oldpassword" placeholder="Ancien mot de passe" required/><br/>
                <input type="password" id="newpassword" placeholder="Nouveau mot de passe" required/><br/>
                <button type="submit" id="submitButton" class="button">Changer mon mot de passe</button>
            </form>
            <div id="authStatus"></div>
            """
        @setDetails form
        $('form').one 'submit', =>
            $('#submitButton').html '<img src="spinner-white.svg">'
            $('#newpassword').attr("readonly", "")
            Utils.changepsw $('#login').val(), $('#oldpassword').val(), $('#newpassword').val(), (err) =>
                if err
                    $('#submitButton').css('display','none')
                    #$('#authStatus').html 'Une erreur fatale est survenue: ' + err + '<br>Impossible de continuer.'
                    @setDetails "Une erreur est survenue: " + err
                    @showEndStepButton()
                else
                    $('#submitButton').css('display','none')
                    @setStatusText "Votre mot de passe à bien été mis à jour."
                    @setDetails ""
                    @showEndStepButton()

    importMailAccount: =>
        @setOperationName "Importation de votre compte mail ISEN"
        @setStatusText ""
        @setDetails ""
        @showProgressBar false
        Utils.isMailActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue: " + err
                @showEndStepButton()
            else if active
                @setStatusText 'Importation en cours...<img id=spinner src="spinner.svg">'
                Utils.importMailAccount
                    username: @formData.username
                    password: @formData.password
                , (err, imported) =>
                    if err
                        @setStatusText 'Importation en cours...'
                        @setDetails "Une erreur est survenue: " + err
                        @showEndStepButton()
                    else if imported
                        @setStatusText "Importation du compte e-mail terminée."
                        @setDetails ""
                        @setProgress 100
                        @showEndStepButton()
                    else
                        @setStatusText "Votre compte e-mail ISEN est déjà configuré dans votre Cozy."
                        @setDetails ""
                        @setProgress 100
                        @showEndStepButton()
            else
                @setStatusText "Cette fonctionnalité a été désactivée par l'administrateur de l'application."
                @setDetails ""
                @setProgress 100
                @showEndStepButton()

    importAdminContacts: =>
        @setOperationName "Importation des contacts administratifs"
        @setStatusText ""
        @setDetails ""
        @showProgressBar false
        Utils.isAdminContactsActive (err, active) =>
            if err
                @setDetails "Une erreur est survenue: " + err
                @showEndStepButton()
            else if active
                @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur...<img id=spinner src="spinner.svg">'
                Utils.importAdminContacts (err) =>
                    if err
                        @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur...'
                        @setDetails "Une erreur est survenue: " + err
                        @showEndStepButton()
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
                @showEndStepButton()

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

                    @showEndStepButton()

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
                @showEndStepButton()


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

                    @showEndStepButton()

    checkStudentsContactsRetrieveStatus: (err, json, over) =>
        @over = false
        if err
            console.log err
            @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur.'
            @setDetails "Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application."
            @showEndStepButton()
        else
            if json.group isnt @lastGroup
                @lastGroup = json.group
                @setDetails 'En train d\'explorer le groupe '+json.group
            if over
                @setStatusText 'Etape 1/2 : Récupération des contacts depuis le serveur.'
                @setStatusText "Récupération des contacts terminée."
                clearInterval @timer
                @importStudentsContacts()