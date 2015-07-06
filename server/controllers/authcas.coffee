cozydb      = require 'cozydb'
requestRoot = require 'request'
#require('request').debug = true
htmlparser  = require 'htmlparser2'
tough       = require 'tough-cookie'
Login = require '../models/login'

#casUrl = 'https://cas-test.cozycloud.cc/'
casUrl = 'https://web.isen-bretagne.fr/cas/'
service = 'https://ent-proxy.cozycloud.cc/'

map = (doc) ->
  emit doc._id, doc

Login.defineRequest "all", map, (err) ->
  if err
    console.log err

module.exports.logIn = (req, res, next) ->
  if not req.body.username or not req.body.password
    console.error 'Error: No data received.'
    res.send status: false
  else
    console.log 'Attempting connection as '+req.body.username+'.'
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
      parser.write body
      parser.end()
      request.post
        url: casUrl+'login'+jsessionid+'?service='+service
        form:
          username: req.body.username
          password: req.body.password
          lt: lt
          submit: "LOGIN"
          _eventId: "submit"
      , (err, status, body) ->
        if err
          console.error  'Error: '+err
        # HTTP 302 Redirect means that CAS accepted our credentials
        if status.statusCode is 302
          console.log 'Connection successful, saving user data...'
          tgc = ""
          cookies = j.getCookies casUrl
          cookies.forEach (cookie) ->
            if cookie.key is "CASTGC"
              tgc = cookie.toJSON()
            if cookie.key is "JSESSIONID"
              Login.create
                username: req.body.username
                password: req.body.password
                tgc: tgc
                jsessionid: cookie.toJSON()
              , ->
                console.log 'User data saved in CozyDB.'
                res.send status: true
        else
          res.send status: false
          console.error 'Error: Attempted to connect as '+req.body.username+' (with password '+req.body.password+') with no success.'

module.exports.check = (req, res, next) ->
  Login.request 'all', (err, logins) ->
    if err
      console.error err
    if logins.length > 0
      res.send isLoggedIn: true
    else
      res.send isLoggedIn: false

module.exports.getAuthUrl = (req, res, next) ->
  switch req.params.pageid
    when "moodle" then service = "moodle/login/index.php"
    when "webAurion" then service = "webAurion/j_spring_cas_security_check"
    when "horde" then service = "horde/login.php"
  Login.request 'all', (err, logins) ->
    if err
      console.error err
    # We're supposed to have only one result here
    login = logins[0]
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
        # Seems like CAS redirects 3 times before delivering the ST. WTF.
        request
          url: casUrl+'?service=https://web.isen-bretagne.fr/'+service
        , (err, status, body) ->
          request
            url: status.headers.location
          , (err, status, body) ->
            res.send url: status.headers.location
            console.log 'Just sent '+status.headers.location

module.exports.logout = (req, res, next) ->
  Login.request 'all', (err, logins) ->
    logins.forEach (login) ->
      login.destroy (err) ->
        if err
          console.error err
    console.log 'All credentials removed.'
    res.send ''
