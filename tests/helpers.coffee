
# See cozy-fixtures documentation for testing on
# https://github.com/jsilvestre/cozy-fixtures#automatic-tests
fixtures = require 'cozy-fixtures'
fs = require 'fs'
path = require 'path'

helpers = {}

# server management
helpers.options = {}
helpers.app = null

helpers.startApp = (done) ->
    americano = require 'americano'

    host = helpers.options.serverHost || "127.0.0.1"
    port = helpers.options.serverPort || 9250

    americano.start name: 'template', host: host, port: port, (app, server) =>
        @app = app
        @app.server = server
        done()

helpers.stopApp = (done) ->
    @app.server.close done

# database helper
helpers.cleanDB = (done) -> fixtures.resetDatabase callback: done
helpers.cleanDBWithRequests = (done) ->
    fixtures.resetDatabase removeAllRequests: true, callback: done
    
helpers.validUsername = null
helpers.validPassword = null
helpers.validService = null

helpers.setMode = (mode) ->
    if mode is "test"
        @validUsername = "brendan"
        @validPassword = "brendan"
        @validService = "app1"
    else if mode is "prod"
        @validUsername = "baboli18"
        @validPassword = "p4Ssw0rd"
        @validService = "moodle"
        
helpers.defineMode = ->
    mode = fs.readFileSync(path.resolve(__dirname, '../conf.coffee'), encoding: 'utf8').match(/conf\.(.+)\.json/)[1]
    @setMode mode

module.exports = helpers
