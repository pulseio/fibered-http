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
    @statusCode = 200
    
    @stub = sinon.stub http, 'request', (options) =>
      req = new events.EventEmitter()

      req.setTimeout = (timeout, cb) =>
        @timeout = setTimeout =>
          cb()
        , timeout

      req.end = =>      
        process.nextTick =>
          
          if @reqClose
            req.emit 'close', new Error("Socket closed")
            return

          if @reqError
            req.emit 'error', @reqError
            return

          unless @timeout        
            res = new events.EventEmitter()
            res.statusCode = 200
            req.emit 'response', res
            process.nextTick =>
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
      (-> fiberedHttp.request({timeout: 10})).should.throw /timeout/i
      
    it 'should throw on request error', ->
      @reqError = new Error('foo')
      (-> fiberedHttp.request({})).should.throw /foo/
      
    it 'should throw on response close', ->
      @resClose = true
      (-> fiberedHttp.request({})).should.throw /socket/i

    it 'should throw on response error', ->
      @resError = new Error("foo")
      (-> fiberedHttp.request({})).should.throw /foo/
      
    it 'should return request', ->
      @statusCode = 200
      fiberedHttp.request({}).statusCode.should.eql @statusCode
      
    it 'should add body to request', ->
      @body = 'foo bar'
      fiberedHttp.request({}).body.should.eql @body