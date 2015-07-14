should  = require 'should'
sinon   = require 'sinon'
Client  = require('request-json').JsonClient
Login   = require '../server/models/login'

helpers = require './helpers'
helpers.options =
    serverHost: 'localhost'
    serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

describe "ISEN CAS Auth - .auth", ->

    before helpers.startApp
    after helpers.stopApp

    describe "When the credentials are valid", ->
        @timeout 10000
        @username = "invite"
        @password = "isen29"
        @status = null

        before =>
          @sandbox = sinon.sandbox.create()
          @create = @sandbox.stub Login, 'create', (data, callback) ->
            callback null

        after => @sandbox.restore()

        it "they should be saved", (done) =>
          Login.auth @username, @password, (err, status) =>
            @status = status
            should.not.exist err
            @create.callCount.should.equal 1
            done()

        it "the correct status code should be returned", =>
          should.exist @status
          @status.should.equal true

    describe "When the credentials are not valid", ->
        @timeout 10000
        @username = "foo"
        @password = "bar"
        @status = null

        before =>
          @sandbox = sinon.sandbox.create()
          @create = @sandbox.stub Login, 'create', (data, callback) ->
            callback null

        after => @sandbox.restore()

        it "they should not be saved", (done) =>
          Login.auth @username, @password, (err, status) =>
            @status = status
            should.not.exist err
            @create.callCount.should.equal 0
            done()

        it "the correct status code should be returned", =>
          should.exist @status
          @status.should.equal false
