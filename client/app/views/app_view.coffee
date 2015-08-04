BaseView = require '../lib/base_view'

module.exports = class AppView extends BaseView

    el: 'body.application'
    template: require('./templates/home')

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
                    $('input#username').attr("readonly", "")
                    $('input#password').attr("readonly", "")
                    if $('#contact').prop('checked') is true
                        console.log "yolo"
                    else
                        console.log "prout"
                    @goToDefaultService()
                else
                    $('#status').html 'Erreur'
            error: =>
                $('#status').html 'Erreur HTTP'

    goToDefaultService: =>
        $.ajax
            type: "GET"
            dataType: "text"
            async: false
            url: 'defaultService'
            success: (data) ->
                window.location = "#" + data