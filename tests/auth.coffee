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

    describe "When the credentials match", ->

        before ->
          @sandbox = sinon.sandbox.create()
          @create = @sandbox.spy Login, 'create'
          @username = "invite"
          @password = "isen29"
          @status = null

        after -> @sandbox.restore()

        it "they should be saved", ->
          Login.auth @username, @password, (err, status) =>
            @status = status
            should.not.exist err
            should.exist @status
            @create.callCount.should.equal 1
            done()

        it "the correct status code should be returned", ->
          @status.should.equal true
