BaseView = require '../lib/base_view'

module.exports = class AppView extends BaseView

    el: 'body.application'
    template: require('./templates/home')

    canclick: true

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
        if @canclick
            @canclick = false
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
                        @goToDefaultService()
                    else
                        $('#status').html 'Erreur'
                        @canclick = true
                error: =>
                    $('#status').html 'Erreur HTTP'
                    @canclick = true

    goToDefaultService: =>
        $.ajax
            type: "GET"
            dataType: "text"
            async: false
            url: 'defaultService'
            success: (data) ->
                window.location = "#" + data