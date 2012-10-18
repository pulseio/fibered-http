Future = require 'fibers/future'
http = require 'http'
https = require 'https'
url = require 'url'
querystring = require 'querystring'

extend = (dest, sources...) ->
  for s in sources
    for key, val of s
      dest[key] = val
  dest


class Request
  constructor: (options) ->

    defaults =
      maxRedirects: 10
      followRedirects: true
    
    @options = extend({}, defaults, options)

    if @options.url
      parsed = url.parse(@options.url)
      @options = extend({hostname: parsed.hostname, port: parsed.port || 80, protocol: parsed.protocol, path: parsed.path}, @options)
      delete @options.url
    
    if @options.query
      [path, query] = (@options.path || '').split('?')
      query = querystring.parse(query)
      qs = querystring.stringify(extend(query, @options.query))
      if qs.length > 0
        @options.path = (path || '') + '?' + qs
      delete @options.query
       
  send: ->
    
    future = new Future
    
    protocol = if @options.protocol?.match(/^https/) then https else http    
    
    req = protocol.request(@options)

    if @options.timeout
      req.setTimeout @options.timeout, ->
        req.end()
        future.throw new Error("Http Timeout") unless future.isResolved()
                  
    req.on 'error', (err) ->
      future.throw err unless future.isResolved()
      
    req.on 'response', (res) => @response(res, future)

    req.write(@options.requestBody) if @options.requestBody
    req.end()
    
    future.wait()

  response: (res, future) ->
    if Math.floor(res.statusCode/100) == 3 and @options.followRedirects and @options.maxRedirects > 0
      @redirect(res.headers.Location || res.headers.location, future)

    else
      body = ''

      res.on 'close', (err) ->      
        future.throw err unless future.isResolved()

      res.on 'error', (err) ->
        future.throw err unless future.isResolved()

      res.on 'data', (data) -> body += data
      res.on 'end', ->
        unless future.isResolved()
          future.return
            body: body
            headers: res.headers
            trailers: res.trailers
            statusCode: res.statusCode
            httpVersion: res.httpVresion    

  redirect: (location, future) ->

    if Fiber.current
      future.return(new Request(extend(@options, {maxRedirects: @options.maxRedirects - 1})).send())
    else
      Fiber(=> @redirect(location, future)).run()         
    
exports.request = request = (options) ->
  new Request(options).send()

# Export put, post, and delete with additional body argument and automatic method setting
for method in ['put', 'post', 'delete']
  exports[method] = do (method) ->
    (body, options) ->
      request extend({}, {body: body, method: method.toUpperCase()}, options)

# Export get without body but with method already set
exports.get = (options) ->
  request extend({}, {method: 'GET'}, options)