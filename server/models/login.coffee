cozydb          = require 'cozydb'
requestRoot     = require 'request'
#require('request').debug = true
htmlparser      = require 'htmlparser2'
tough           = require 'tough-cookie'
conf            = require '../../conf.coffee'
printit         = require 'printit'

log = printit
    prefix: 'models:login'
    date: true

###
    Class Login
    Manages authentication through CAS
    Please read https://github.com/babolivier/cozy-isen-ent/wiki/Basic-CAS-documentation
    before this code to understand it better
###

module.exports = class Login extends cozydb.CozyModel
    @docType: 'CASLogin'

    @schema:
        username: String
        password: String
        tgc: Object
        jsessionid: Object

    @casUrl: conf.casUrl

    # auth: Check the validity of the credentials received and, if valid,
    #   stores them in the data-system
    #
    # username: user's username
    # password: user's password
    # callback(err, status); status: connection status (true if succeeded, or false)

    @auth: (username, password, callback) =>
        log.info 'Attempting connection as '+username+' (password: '+password+').'
        service = 'https://ent-proxy.cozycloud.cc/'
        if not username or not password
            log.error 'No data received.'
            callback null, false
        else
            j = requestRoot.jar()
            request = requestRoot.defaults
                jar:j
            lt = ""
            jsessionid = ""
            parser = new htmlparser.Parser
                onopentag: (name, attribs) ->
                    if name is 'input' and attribs.name is 'lt'\
                    and attribs.type is 'hidden'
                        lt = attribs.value
                    if name is 'form' and attribs.id is 'fm1'
                        action = attribs.action
                        if action.match(/;jsessionid=(.+)/) isnt null
                            jsessionid = action.match(/;jsessionid=(.+)/)[0]
                        else
                            jsessionid = ""
            , decodeEntities: true
            request
                url: @casUrl+'login?service='+service
            , (err, status, body) =>
                if err
                    callback err
                else
                    parser.write body
                    parser.end()
                    request.post
                        url: @casUrl+'login'+jsessionid+'?service='+service
                        form:
                            username: username
                            password: password
                            lt: lt
                            submit: "LOGIN"
                            _eventId: "submit"
                    , (err, status, body) =>
                        if err
                            callback err
                        else
                            # HTTP 302 Redirect means that CAS accepted our credentials
                            if status.statusCode is 302
                                log.info 'Connection successful, saving user data...'
                                tgc = ""
                                jsessionid = ""
                                cookies = j.getCookies @casUrl
                                cookies.forEach (cookie) ->
                                    if cookie.key is "CASTGC"
                                        tgc = cookie.toJSON()
                                    if cookie.key is "JSESSIONID"
                                        jsessionid = cookie.toJSON()
                                Login.create
                                    username: username
                                    password: password
                                    tgc: tgc
                                    jsessionid: jsessionid
                                , (err, login) ->
                                    console.log login
                                    log.info 'User data saved in the Data System.'
                                    callback null, true
                            else
                                log.error 'Attempted to connect as '+username+' with no success'
                                callback null, false

    # authRequest: Uses the information stored in the data-system to perform
    #   a request of an authenticated service
    #
    # service: Service slug (set in the configuration file)
    # callback(err, authUrl); authUrl: URL to return to the client

    @authRequest: (service, callback) =>
        Login.request 'all', (err, logins) =>
            if err
                callback err
            else
                if logins.length is 0
                    callback "No user logged in"
                else
                    login = logins[logins.length-1]
                    @getConfiguredRequest service, login, (err, request) =>
                        if err
                            callback err
                        else
                            request uri:'', (err, status, body) =>
                                if err
                                    log.error err
                                else
                                    if status.statusCode is 200
                                        # If no redirection: Cookies have expired, let's log back in
                                        username = login.username
                                        password = login.password
                                        log.info 'Cookies expired, logging back in'
                                        @logAllOut (err) =>
                                            callback err
                                            console.log err
                                            @auth username, password, (err, status) =>
                                                if err
                                                    callback err
                                                else
                                                    if status
                                                        @authRequest service, callback
                                                    else
                                                        callback "Can't connect to CAS"
                                    else if status.statusCode is 302
                                        log.info 'Sending '+status.headers.location
                                        callback null, status.headers.location

    # logAllOut: Disable the CAS cookies and erases all credentials from the
    #   data-system
    #   The disabling is made by hitting /logout on the CAS server with
    #   the said cookies
    #
    # callback(err); if err is null, it means that everything went well

    @logAllOut: (callback) =>
        Login.request 'all', (err, logins) =>
            if err
                callback err
            else
                i = 0
                nbToDelete = logins.length
                loginDeleted = nbToDelete
                logins.forEach (login) =>
                    j = requestRoot.jar()
                    Cookie = tough.Cookie
                    tgc = Cookie.fromJSON login.tgc
                    jsessionid = Cookie.fromJSON login.jsessionid
                    j.setCookie tgc.toString(), @casUrl, =>
                        j.setCookie jsessionid.toString(), @casUrl, =>
                            request = requestRoot.defaults
                                jar: j
                                followRedirect: true
                            # Disabling stored cookies
                            request
                                url: @casUrl+'logout'
                            , (err, status, body) =>
                                if err
                                    callback err
                                else
                                    login.destroy (err) =>
                                        i++
                                        if err
                                            log.error err
                                            loginDeleted--
                                        if i is nbToDelete
                                            log.info loginDeleted + ' over ' + nbToDelete + ' credential(s) removed from the Data System'
                                            callback null

    # getConfiguredRequest: returns a modified request object configured to ask
    #   for the right service in @authRequest
    #
    # serviceSlug: The requested service's slug
    # login: The login object from the data-system

    @getConfiguredRequest: (serviceSlug, login, callback) ->
        # Matching the right service URL
        url = null
        for service in conf.servicesList
            if serviceSlug is service.clientServiceUrl
                log.info 'Requesting '+serviceSlug+' as '+login.username
                url = service.serverServiceUrl
        if url is null
            callback "Unknown service '"+serviceSlug+"'"
        else
            # Let's load CAS's auth cookie we previously stored and create our request
            # object from it
            j = requestRoot.jar()
            Cookie = tough.Cookie
            tgc = Cookie.fromJSON login.tgc
            jsessionid = Cookie.fromJSON login.jsessionid
            j.setCookie tgc.toString(), @casUrl, =>
                j.setCookie jsessionid.toString(), @casUrl, =>
                    request = requestRoot.defaults
                        jar: j
                        followRedirect: false
                        baseUrl: @casUrl+'login?service='+url
                    callback null, request
