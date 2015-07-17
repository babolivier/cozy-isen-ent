Login   = require '../models/login'
printit = require 'printit'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.logIn = (req, res, next) ->
    Login.auth req.body.username, req.body.password, (err, status) ->
        if err
            log.error err
            res.send error: err
        else
            res.send status: status

module.exports.check = (req, res, next) ->
    Login.request 'all', (err, logins) ->
        if err
            log.error err
            res.send error: err
        if logins.length > 0
            res.send isLoggedIn: true
        else
            res.send isLoggedIn: false

module.exports.getAuthUrl = (req, res, next) ->
    Login.authRequest req.params.pageid, (err, authUrl) ->
        if err
            log.error err
            res.send error: err
        else
            res.send url: authUrl

module.exports.logout = (req, res, next) ->
    Login.logAllOut (err, status) ->
        if err
            log.error err
            res.send error: err
        else
            if status
                res.send ''

module.exports.logInTest = (req, res, next) ->
    Login.auth "brendan", "brendan", (err, status) ->
        if err
            log.error err
            res.send error: err
        else
            res.send status: status