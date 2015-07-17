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

    renderPage: (pageid, oldpage) =>
        if typeof oldpage is 'undefined'
            oldpage =
                url: 'moodle'
        return $.get 'authUrl/'+pageid, '', (data) =>
            if data.error
                if data.error is "No user logged in"
                    window.location = "#login"
                    return
                else
                    @error = data.error
                    @url = ""
            else
                @url = data.url
            @render()
        , 'json'

    logout: ->
        $.get 'logout', '', =>
            window.location = "#login"

    afterRender: =>
        if @error
            @showError @error
        $.ajax
            type: "GET"
            dataType: "json"
            async: false
            url: 'services'
            success: (data) ->
                for key, service of data
                    li =
                        '<li class="serviceButton">
                            <a href="#'+service.clientServiceUrl+'">
                                <i class="'+service.clientIcon+'"></i>
                                <span>'+service.displayName+'</span>
                            </a>
                        </li>'
                    $("#servicesMenu").append(li)
            error: (err) =>
                @showError err.status + " : " + err.statusText + "<br>" + err.responseText

    showError: (err) =>
        $("#errorText").html err
        $("#errors").removeClass 'off-error'
        $("#errors").addClass 'on-error'

    hideError: (e)=>
        if e.type is "click" or e.keyCode is 13 or e.keyCode is 27
            $("#errors").removeClass 'on-error'
            $("#errors").addClass 'off-error'