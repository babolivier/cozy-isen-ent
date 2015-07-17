should    = require 'should'
sinon     = require 'sinon'
Client    = require('request-json').JsonClient
Login     = require '../server/models/login'

helpers = require './helpers'
helpers.options =
        serverHost: 'localhost'
        serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

#helpers.setMode "test"
helpers.setMode "prod"

describe.skip "ISEN CAS Auth - .logAllOut", ->

        before helpers.startApp
        after helpers.stopApp

        describe "When the function is called", ->
            @timeout 10000
            @username = helpers.validUsername
            @password = helpers.validPassword
            @status = null

            before (done) =>
                @sandbox = sinon.sandbox.create()
                @destroy = @sandbox.spy Login, 'destroy'
                Login.auth @username, @password, (err, status) =>
                    done()

            after => @sandbox.restore()

            it "the credentials should be removed", (done) =>
                Login.logAllOut (err, status) =>
                    @status = status
                    should.not.exist err
                    @destroy.callCount.should.not.equal 0
                    done()

            it "the correct status code should be returned", =>
                @status.should.equal true
