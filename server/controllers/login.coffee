Login       = require '../models/login'
printit     = require 'printit'

log = printit
    prefix: 'ent-isen'
    date: true

module.exports.logIn = (req, res, next) ->
    Login.auth req.body.username, req.body.password, (err, status) ->
        if err
            log.error err
            res.status(500).json error: err
        else if not status
            res.status(401).json status: status
        else
            res.status(200).json status: status

module.exports.check = (req, res, next) ->
    Login.request 'all', (err, logins) ->
        if err
            log.error err
            res.status(500).json error: err
        else if logins.length > 0
            res.status(200).json isLoggedIn: true
        else
            res.status(401).json isLoggedIn: false

module.exports.getAuthUrl = (req, res, next) ->
    Login.authRequest req.params.pageid, (err, authUrl) ->
        if err
            log.error err
            switch err
                when "No user logged in" then res.status(401).json {error: err, service: req.params.pageid}
                when "Unknown service " + err.slice("Unknown service ".length) then res.status(400).json {error: err, service: req.params.pageid}
                else res.status(500).json error: err
        else
            res.status(200).json url: authUrl

module.exports.logout = (req, res, next) ->
    Login.logAllOut (err) ->
        if err
            log.error err
            res.status(500).json error: err
        else
            res.status(200).json loggedOut: true
