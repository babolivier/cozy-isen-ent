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
            success: (data) =>
                for key, service of data
                    if service.clientLogoutUrl
                        @serviceData.push
                            name: service.displayName
                            logOutUrl: service.clientLogoutUrl
                @logoutStatus =
                    numServicesToLogOut: @serviceData.length + 1#+1 for server deco
                    numServicesLoggedOut: 0
            error: (err) =>
                @serviceData.err = err

    logout: ->


    afterRender: =>
        setTimeout =>
            window.location = "#login"
        , 5000
        console.log "<p>Déconnexion de l'application cozy</p>"
        $.ajax
            type: "GET"
            dataType: "json"
            async: true
            url: "logout"
            success: (data) =>
                if data.error
                    console.log "<p>L'application cozy à renvoyée l'erreur suivante: " + data.error + "</p>"
                else
                    console.log "<p>L'application cozy est déconnectée du serveur CAS.</p>"
                    @checkLogout()
            error: (err) =>
                console.log "<p>Impossible de joindre l'application cozy: " + err + "</p>"
                console.log err

        if not @serviceData.err
            for key, service of @serviceData
                console.log '<p>Déconnexion du service ' + service.name + ' sur l\'url: ' + service.logOutUrl + '</p>'
                onLoad = =>
                    sname = service.name
                    return =>
                        console.log '<p>Service ' + sname + ' déconecté.</p>'
                        @checkLogout()
                $("#logoutIframes").append('<iframe src="' + service.logOutUrl + '"></iframe>')
                .children().last().one "load", onLoad()
        else
            console.log '<p>Une erreur est survenue lors de la récupération de la liste des services: ' + @serviceData.err + '</p>'

    checkLogout: =>
        @logoutStatus.numServicesLoggedOut++
        if @logoutStatus.numServicesLoggedOut is @logoutStatus.numServicesToLogOut
            console.log '<p>Déconnexion de tout les services et du serveur CAS effectuée.</p>'
            window.location = "#login"