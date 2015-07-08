cozydb      = require 'cozydb'
requestRoot = require 'request'
htmlparser  = require 'htmlparser2'
tough       = require 'tough-cookie'

#casUrl = 'https://cas-test.cozycloud.cc/'
casUrl = 'https://web.isen-bretagne.fr/cas/'
service = 'https://ent-proxy.cozycloud.cc/'

module.exports = class Login extends cozydb.CozyModel
  @docType = 'CASLogin'

  @schema =
    username: String
    password: String
    tgc: Object
    jsessionid: Object

  @auth = (username, password, callback) ->
    if not username or not password
      console.error 'Error: No data received.'
      callback null, false
    else
      console.info 'Attempting connection as '+username+'.'
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
        url: casUrl+'login?service='+service
      , (err, status, body) ->
        if err
          callback err
        parser.write body
        parser.end()
        request.post
          url: casUrl+'login'+jsessionid+'?service='+service
          form:
            username: username
            password: password
            lt: lt
            submit: "LOGIN"
            _eventId: "submit"
        , (err, status, body) ->
          if err
            callback err
          # HTTP 302 Redirect means that CAS accepted our credentials
          if status.statusCode is 302
            console.info 'Connection successful, saving user data...'
            tgc = ""
            jsessionid = ""
            cookies = j.getCookies casUrl
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
              console.info 'User data saved in CozyDB.'
              callback null, true
          else
            console.error 'Error: Attempted to connect as '+username+' with no success.'
            callback null, false

  @authRequest = (url, callback) ->
    Login.request 'all', (err, logins) ->
      if err
        next err
      # Let's take the latest result here
      login = logins[logins.length-1]
      # Let's load CAS's auth cookie we previously stored and create our request
      # object from it
      j = requestRoot.jar()
      Cookie = tough.Cookie
      tgc = Cookie.fromJSON login.tgc
      jsessionid = Cookie.fromJSON login.jsessionid
      j.setCookie tgc.toString(), casUrl, ->
        j.setCookie jsessionid.toString(), casUrl, ->
          request = requestRoot.defaults
            jar: j
            followRedirect: false
          request
            url: casUrl+'login?service=https://web.isen-bretagne.fr/'+url
            #url: casUrl+'login?service=https://ent-proxy.cozycloud.cc/app1'
          , (err, status, body) ->
            if status.statusCode is 200
              # If no redirection: Cookies have expired, let's log back in
              username = login.username
              password = login.password
              login.destroy (err) ->
                if err
                  callback err
              console.info 'Cookies expired, logging back in'
              @auth username, password, (err, status) ->
                if err
                  callback err
                else
                  if status
                    @authRequest url, callback
                  else
                    callback "Can't connect to CAS"
            else if status.statusCode is 302
              console.info 'Sending '+status.headers.location
              callback null, status.headers.location
