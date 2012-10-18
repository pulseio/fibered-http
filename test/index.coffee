sinon = require 'sinon'
should = require 'should'
events = require 'events'
fiberedHttp = require '../lib'
http = require 'http'
https = require 'https'

describe 'fibered-http', ->

  beforeEach ->
    @reqError = null
    @resError = null
    @reqClose = false
    @resClose = false
    @body = ''
    @timeout = null
    @statusCode = 200
    @options = null
    @redirects = null
    
    @stub = sinon.stub http, 'request', (options) =>
      @options = options
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
            if @redirects && @redirects > 0
              res.statusCode = 302
              res.headers = {'Location': 'http://foo'}
              @redirects--
            else
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

    it 'should allow full urls', ->
      fiberedHttp.request({url: 'http://www.foo.com:3000/path?query=foo'})
      @options.hostname.should.eql 'www.foo.com'
      @options.path.should.eql '/path?query=foo'
      @options.port.should.eql '3000'
      
    it 'should use proper protocol', ->
      stub = sinon.stub(https, 'request', http.request)
      fiberedHttp.request({url: 'https://www.foo.com'})
      stub.called.should.be.true
      stub.restore()

    describe 'with query', ->

      it 'should append query to path', ->
        fiberedHttp.request({path: '/foo', query: {foo: 'bar'}})
        @options.path.should.eql '/foo?foo=bar'
          
      it 'should merge query with query already in path', ->
        fiberedHttp.request({path: '/foo?foo=bar', query: {hello: 'world'}})
        @options.path.should.eql '/foo?foo=bar&hello=world'
        
      it 'should handle missing path', ->
        fiberedHttp.request({query: {foo: 'bar'}})
        @options.path.should.eql '?foo=bar'

    describe 'with redirects', ->
      beforeEach ->
        @redirects = 5

      it 'should follow redirects', ->
        fiberedHttp.request({url: 'http://bar'})
        @stub.callCount.should.eql 6
        
      it 'should not follow more than maxRedirects', ->
        fiberedHttp.request({url: 'http://bar', maxRedirects: 1})
        @stub.callCount.should.eql 2

      describe 'followRedirects = false', ->
        it 'should not follow redirects', ->
          fiberedHttp.request({url: 'http://bar', followRedirects: false})
          @stub.callCount.should.eql 1
        
      