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

exports.request = request = (options = {}) ->
  f = new Future

  # Clone options to prevent mutating parameter
  options = extend({}, options)

  # Handle extra options  
  delete options.timeout if timeout = options.timeout
  delete options.body if requestBody = options.body

  if options.url
    parsed = url.parse(options.url)
    options = extend({hostname: parsed.hostname, port: parsed.port || 80, protocol: parsed.protocol, path: parsed.path}, options)
    delete options.url
  
  if options.query
    [path, query] = (options.path || '').split('?')
    query = querystring.parse(query)
    qs = querystring.stringify(extend(query, options.query))
    if qs.length > 0
      options.path = (path || '') + '?' + qs
    delete options.query
            
  protocol = if options.protocol?.match(/^https/) then https else http    
  
  req = protocol.request(options)

  if timeout
    req.setTimeout timeout, ->
      req.end()
      f.throw new Error("Http Timeout") unless f.isResolved()
      
        
  req.on 'error', (err) ->
    f.throw err unless f.isResolved()
    
  req.on 'response', (res) ->
    body = ''
    
    res.on 'close', (err) ->      
      f.throw err unless f.isResolved()

    res.on 'error', (err) ->
      f.throw err unless f.isResolved()
      
    res.on 'data', (data) -> body += data
    res.on 'end', ->
      unless f.isResolved()
        f.return
          body: body
          headers: res.headers
          trailers: res.trailers
          statusCode: res.statusCode
          httpVersion: res.httpVresion

  req.write(requestBody) if requestBody
  req.end()
  
  f.wait()

# Export put, post, and delete with additional body argument and automatic method setting
for method in ['put', 'post', 'delete']
  exports[method] = do (method) ->
    (body, options) ->
      request extend({}, {body: body, method: method.toUpperCase()}, options)

# Export get without body but with method already set
exports.get = (options) ->
  request extend({}, {method: 'GET'}, options)