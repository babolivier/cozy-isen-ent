Login       = require '../models/login'

module.exports.logIn = (req, res, next) ->
  Login.auth req.body.username, req.body.password, (err, status) ->
    if err
      next err
    else
      res.send status: status

module.exports.check = (req, res, next) ->
  Login.request 'all', (err, logins) ->
    if err
      next err
    if logins.length > 0
      res.send isLoggedIn: true
    else
      res.send isLoggedIn: false

module.exports.getAuthUrl = (req, res, next) ->
  switch req.params.pageid
    when "moodle" then serviceUrl = "moodle/login/index.php"
    when "webAurion" then serviceUrl = "webAurion/j_spring_cas_security_check"
    when "horde" then serviceUrl = "horde/login.php"
    #when "app1" then serviceUrl="app1/index.php"
  Login.authRequest serviceUrl, (err, authUrl) ->
    if err
      next err
    else
      res.send url: authUrl

module.exports.logout = (req, res, next) ->
  Login.logAllOut (err, status) ->
    if err
      next err
    else
      if status
        res.send ''

module.exports.logInTest = (req, res, next) ->
  Login.auth "brendan", "brendan", (err, status) ->
    if err
      next err
    else
      res.send status: status
