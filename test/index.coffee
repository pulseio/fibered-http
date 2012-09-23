sinon = require 'sinon'
should = require 'should'
events = require 'events'
fiberedHttp = require '../lib'
http = require 'http'

describe 'fibered-http', ->

  beforeEach ->
    @reqError = null
    @resError = null
    @reqClose = false
    @resClose = false
    @body = ''
    @timeout = null
    
    @stub = sinon.stub http, 'request', (options) ->
      req = new events.EventEmitter()

      req.setTimeout = (timeout, cb) ->
        @timeout = setTimeout ->
          cb()
        , timeout

      req.end = ->      
        process.nextTick ->
          
          if @reqClose
            req.emit 'close', new Error("Socket closed")
            return

          if @reqError
            req.emit 'error', @reqError
            return

          unless @timeout        
            res = new events.EventEmitter()
            res.emit 'response', res

            process.nextTick ->
              if @resClose
                res.emit 'close', new Error("Socket closed")
                return

              if @resError
                res.emit 'error', @resError
                return
              
              res.emit 'data', @body
              res.emit 'end'
            
      return req
          
  afterEach ->
    @stub.restore()
    
  describe 'request', ->

    it 'should throw on timeout', ->
      @timeout = 10      
      fiberedHttp.request({timeout: 10}).should.throw
      
    it 'should throw on request error', ->
      @reqError = new Error(foo)
      fiberedHttp.request({}).should.throw
      
    it 'should throw on request close'
    it 'should return request'
    it 'should add body to request', ->
      @body = 'foo bar'
      fiberedHttp.request({}).should.eql @body