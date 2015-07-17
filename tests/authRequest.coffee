should    = require 'should'
sinon     = require 'sinon'
Client    = require('request-json').JsonClient
Login     = require '../server/models/login'

helpers = require './helpers'
helpers.options =
        serverHost: 'localhost'
        serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

helpers.setMode "test"
#helpers.setMode "prod"

describe "ISEN CAS Auth - .authRequest", ->

        before helpers.startApp
        after helpers.stopApp

        describe "When the user is logged in and requests a known service", ->
                @timeout 10000
                @username = helpers.validUsername
                @password = helpers.validPassword
                @service = helpers.validService
                @authUrl = null

                before (done) =>
                    @sandbox = sinon.sandbox.create()
                    Login.auth @username, @password, (err, status) =>
                        done()

                after (done) =>
                    @sandbox.restore()
                    Login.request 'all', (err, logins) ->
                        logins[logins.length-1].destroy (err) ->
                            done()

                it "no error is thrown", (done) =>
                    Login.authRequest @service, (err, authUrl) =>
                        @authUrl = authUrl
                        should.not.exist err
                        done()

                it "a URL with a Service Ticket should be returned", =>
                    should.exist @authUrl
                    should.exist @authUrl.match(/ticket=(.+)/)

        describe "When the user is logged in and requests an unknown service", ->
                @timeout 10000
                @username = helpers.validUsername
                @password = helpers.validPassword
                @service = 'foobar'
                @authUrl = null

                before (done) =>
                    @sandbox = sinon.sandbox.create()
                    Login.auth @username, @password, (err, status) =>
                        done()

                after (done) =>
                    @sandbox.restore()
                    Login.request 'all', (err, logins) ->
                        logins[logins.length-1].destroy (err) ->
                            done()

                it "the correct error is thrown", (done) =>
                    Login.authRequest @service, (err, authUrl) =>
                        @authUrl = authUrl
                        should.exist err
                        err.should.equal "Unknown service 'foobar'"
                        done()

                it "no URL should be returned", ->
                    should.not.exist @authUrl

        describe "When the user is not logged in and requests a known service", ->
                @service = helpers.validService
                @authUrl = null

                before => @sandbox = sinon.sandbox.create()

                after => @sandbox.restore()

                it "the correct error is thrown", (done) =>
                    Login.authRequest @service, (err, authUrl) =>
                        @authUrl = authUrl
                        should.exist err
                        err.should.equal "No user logged in"
                        done()

                it "no URL should be returned", ->
                    should.not.exist @authUrl

        describe "When the user is not logged in and requests an unknown service", ->
                @service = "foobar"
                @authUrl = null

                before => @sandbox = sinon.sandbox.create()

                after => @sandbox.restore()

                it "the correct error is thrown", (done) =>
                    Login.authRequest @service, (err, authUrl) =>
                        @authUrl = authUrl
                        should.exist err
                        err.should.equal "No user logged in"
                        done()

                it "no URL should be returned", ->
                    should.not.exist @authUrl

        describe "When the user is logged in and requests a known service but his TGC has expired", ->
                @timeout 10000
                @username = helpers.validUsername
                @password = helpers.validPassword
                @service = helpers.validService
                @authUrl = null

                before (done) =>
                    @sandbox = sinon.sandbox.create()
                    @auth = @sandbox.spy Login, 'auth'
                    Login.auth @username, @password, (err, status) =>
                        Login.request 'all', (err, logins) ->
                            logins[logins.length-1].tgc.key = "TGT-133-mNhu51Eo2Xmtt5bg7EnoGi9ypfSIYIXlV3fjvaMQUsqA1cYyOU-cas"
                            done()

                after (done) =>
                    @sandbox.restore()
                    Login.request 'all', (err, logins) ->
                        logins[logins.length-1].destroy (err) ->
                            done()

                it "no error is thrown", (done) =>
                    Login.authRequest @service, (err, authUrl) =>
                        @authUrl = authUrl
                        should.not.exist err
                        done()

                it "the user is re-authenticated", =>
                    @auth.callCount.should.equal 1

                it "a URL with a Service Ticket should be returned", =>
                    should.exist @authUrl
                    should.exist @authUrl.match(/ticket=(.+)/)
