cozydb        = require 'cozydb'
requestRoot   = require 'request'
#require('request').debug = true
htmlparser    = require 'htmlparser2'
tough         = require 'tough-cookie'
servicesList  = require '../../services.json'
printit       = require 'printit'

log = printit
  prefix: 'ent-isen'
  date: true

module.exports = class Login extends cozydb.CozyModel
  @docType = 'CASLogin'

  @schema =
    username: String
    password: String
    tgc: Object
    jsessionid: Object

  #@casUrl = 'https://cas-test.cozycloud.cc/'
  @casUrl = 'https://web.isen-bretagne.fr/cas/'

  @auth = (username, password, callback) =>
    service = 'https://ent-proxy.cozycloud.cc/'
    if not username or not password
      log.error 'Error: No data received.'
      callback null, false
    else
      log.info 'Attempting connection as '+username+'.'
      j = requestRoot.jar()
      request = requestRoot.defaults
        jar:j
      lt = ""
      jsessionid = ""
      parser = new htmlparser.Parser
        onopentag: (name, attribs) ->
          if name is 'input' and attribs.name is 'lt' and attribs.type is 'hidden'
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
                , ->
                  log.info 'User data saved in the Data System.'
                  callback null, true
              else
                log.error 'Attempted to connect as '+username+' with no success'
                callback null, false

  @authRequest = (serviceSlug, callback) =>
    Login.request 'all', (err, logins) =>
      if err
        next err
      else
        if logins.length is 0
          callback "No user logged in"
        else
          # Let's take the latest result here
          login = logins[logins.length-1]
          # Matching the right service URL
          url = null
          for service in servicesList
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
                request
                  url: @casUrl+'login?service=https://web.isen-bretagne.fr/'+url
                  #url: @casUrl+'login?service=https://ent-proxy.cozycloud.cc/'+url
                , (err, status, body) ->
                  if status.statusCode is 200
                    # If no redirection: Cookies have expired, let's log back in
                    username = login.username
                    password = login.password
                    login.destroy (err) ->
                      if err
                        callback err
                      else
                        log.info 'Cookies expired, logging back in'
                        @auth username, password, (err, status) ->
                          if err
                            callback err
                          else
                            if status
                              @authRequest url, callback
                            else
                              callback "Can't connect to CAS"
                  else if status.statusCode is 302
                    log.info 'Sending '+status.headers.location
                    callback null, status.headers.location

  @logAllOut = (callback) =>
    Login.request 'all', (err, logins) =>
      if err
        callback err
      else
        i = 0
        nbToDelete = logins.length
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
                      callback err
                    else if i is nbToDelete
                      log.info 'All credentials removed from the Data System'
                      callback null, true
