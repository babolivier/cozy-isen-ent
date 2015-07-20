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
        $('#status').html 'En cours'
        $.ajax
            url: 'login'
            method: 'POST'
            data:
                username: $('input#username').val()
                password: $('input#password').val()
            dataType: 'json'
            success: (data) =>
                $('#status').html 'Connecté, redirection...'
                if data.status
                    @createMailAccount (err) =>
                        if err
                            $('#status').html err
                        else
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
                
    createMailAccount: (callback) =>
        @mailAccountExists (err, doesExists) =>
            if err
                $('#status').html err
            else if doesExists
                # If the e-mail account already exists, we don't need to create it
                callback null
            else
                $.ajax
                    type: "GET"
                    url: 'email'
                    dataType: "text"
                    success: (data) =>
                        if data is ''
                            email = $('input#username').val()+'@isen-bretagne.fr'
                        else
                            email = data
                        @saveMailAccount
                            username: $('input#username').val()
                            password: $('input#password').val()
                            email: email
                        , callback
                            
    mailAccountExists: (callback) ->
        $.ajax
            url: 'email'
            type: 'POST'
            dataType: "json"
            success: (data) ->
                if data.err
                    callback err
                else
                    callback null, data.exists
            error: ->
                callback 'Erreur HTTP'
                    
    saveMailAccount: (data, callback) ->
        $.ajax
            url: '/apps/emails/account'
            method: 'POST'
            data:
                label: 'ISEN'
                name: data.username
                login: data.email
                password: data.password
                accountType: 'IMAP'
                smtpServer: 'smtp.isen-bretagne.fr'
                smtpPort: 465
                smtpSSL: true
                smtpTLS: false
                smtpLogin: data.username
                smtpMethod: 'LOGIN'
                imapLogin: data.username
                imapServer: 'mail.isen-bretagne.fr'
                imapPort: 993
                imapSSL: true
                imapTLS: false
            dataType: 'json'
            success: (data) =>
                callback null
            error: =>
                callback 'Erreur HTTP'