BaseView  = require '../lib/base_view'
AppView   = require 'views/app_view'

module.exports = class PageView extends BaseView

    el: 'body'
    template: require './templates/page'

    error: ''

    events: =>
        'click #closeError': 'hideError'
        'keydown': 'hideError'

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
                else
                    data = xhr
                    @showError data.status + " : " + data.statusText + "<br>" + data.responseText

    showError: (err) =>
        $("#errorText").html err
        $("#errors").removeClass 'off-error'
        $("#errors").addClass 'on-error'

    hideError: (e)=>
        if e.type is "click" or e.keyCode is 13 or e.keyCode is 27
            $("#errors").removeClass 'on-error'
            $("#errors").addClass 'off-error'