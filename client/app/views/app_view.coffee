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
                    window.location = "#moodle"
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
                        window.location = "#moodle"
                    else
                        $('#status').html 'Erreur'
                        @canclick = true
                error: =>
                    $('#status').html 'Erreur HTTP'
                    @canclick = true