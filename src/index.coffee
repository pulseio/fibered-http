Future = require 'fibers/future'
http = require 'http'

extend = (dest, sources...) ->
  for s in sources
    for key in s
      dest[key] = s[key]
  dest

exports.request = request = (options = {}) ->
  f = new Future

  delete options.timeout if timeout = options.timeout
  delete options.body if requestBody = options.body
  
  req = http.get(options)

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
      
    res.on 'data', (data) -> body += data
    res.on 'end', ->
      f.return extend({}, response, {body: body}) unless f.isResolved()

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