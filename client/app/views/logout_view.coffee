BaseView  = require '../lib/base_view'

module.exports = class LogoutView extends BaseView

    el: 'body'
    template: require './templates/logout'

    events: =>

    getRenderData: ->
        res =
            url: @url

    beforeRender: =>
        @serviceData = new Array
        $.ajax
            type: "GET"
            dataType: "json"
            async: false
            url: 'servicesList'
            complete: (xhr) =>
                if xhr.status is 200
                    data = xhr.responseJSON
                    for key, service of data
                        if service.clientLogoutUrl
                            @serviceData.push
                                name: service.displayName
                                logOutUrl: service.clientLogoutUrl
                    @logoutStatus =
                        numServicesToLogOut: @serviceData.length + 1#+1 for server deco
                        numServicesLoggedOut: 0
                else if xhr.status is 504
                    @serviceData.err = "Connection timed out"
                else
                    @serviceData.err = err

    logout: ->


    afterRender: =>
        @timoutId = setTimeout =>
            console.log "Certains services n'ont pas répondus à temps sur leur url de déconnexion. Vous allez être tout de même redirigé sur la page de login."
            window.location = "#login"
        , 5000
        console.log "Déconnexion de l'application cozy..."
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: "logout"
            complete: (xhr) =>
                if xhr.status is 200
                    data = xhr.responseJSON
                    if data.error
                        console.log "L'application cozy à renvoyée l'erreur suivante: " + data.error
                    else
                        console.log "L'application cozy est déconnectée du serveur CAS."
                        @checkLogout()
                if xhr.status is 504
                    console.error "Connection timed out"
                else
                    console.log "Impossible de joindre l'application cozy: " + err

        if not @serviceData.err
            for key, service of @serviceData
                console.log 'Déconnexion du service ' + service.name + ' sur l\'url ' + service.logOutUrl + ' ...'
                onLoad = =>
                    sname = service.name
                    return =>
                        console.log 'Service ' + sname + ' déconecté.'
                        @checkLogout()
                $("#logoutIframes").append('<iframe src="' + service.logOutUrl + '"></iframe>')
                .children().last().one "load", onLoad()
        else
            console.log 'Une erreur est survenue lors de la récupération de la liste des services: ' + @serviceData.err

    checkLogout: =>
        @logoutStatus.numServicesLoggedOut++
        if @logoutStatus.numServicesLoggedOut is @logoutStatus.numServicesToLogOut
            console.log 'Déconnexion de tout les services et du serveur CAS effectuée.'
            clearTimeout(@timoutId)
            window.location = "#login"
