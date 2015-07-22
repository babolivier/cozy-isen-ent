BaseView = require '../lib/base_view'

module.exports = class AppView extends BaseView

    el: 'body.application'
    template: require('./templates/home')
<<<<<<< HEAD

=======
    
>>>>>>> 8bbdb337e9ab5a0b7538fe8e60b827e61d2bbb35
    mail: false
    params: {}

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
                    @mail = data.mail
                    @params = data.params

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
                    if @mail
                        $('#status').html 'Connecté, redirection...'
                        @createMailAccount (err) =>
                            if err
                                $('#status').html err
                            else
                                @goToDefaultService()
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
                            email = $('input#username').val()+'@'+@params.domain
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
<<<<<<< HEAD

=======
                    
>>>>>>> 8bbdb337e9ab5a0b7538fe8e60b827e61d2bbb35
    saveMailAccount: (data, callback) =>
        $.ajax
            url: '/apps/emails/account'
            method: 'POST'
            data:
                label: @params.label
                name: data.username
                login: data.email
                password: data.password
                accountType: "IMAP"
                smtpServer: @params.smtpServer
                smtpPort: @params.smtpPort
                smtpSSL: @params.smtpSSL
                smtpTLS: @params.smtpTLS
                smtpLogin: data.username
                smtpMethod: @params.smtpMethod
                imapLogin: data.username
                imapServer: @params.imapServer
                imapPort: @params.imapPort
                imapSSL: @params.imapSSL
                imapTLS: @params.imapTLS
            dataType: 'json'
            success: (data) =>
                callback null
            error: =>
                callback null