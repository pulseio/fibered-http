fibered-http
============

Wrapper around http and https node.js libraries that uses fiberes to
improve the interface.

Use
===

```javascript
var http = require('fibered-http');
var result = http.request({url: 'http://foo.bar'});
console.log("I have html baby! " + result.body);
```

API
===


request(options)
-------

Issues an http(s) request and immediately returns result, blocking fiber while waiting for a response.  Automatically follows redirects unless explicitly told not to (see followRedirects option).

### options

* *url* -   URL to fetch
* *query* - Object of query parameters.  Will be combined with any existing query parameters in *path* or *url*
* *protocol* - used to select either http or https node.js library for underlying call
* *timeout* - Sets a timeout.  If timeout is triggered, request is cancelled and error is thrown
* *maxRedirects* - Maximum number of times to follow a redirect
* *followRedirects* - if false, will not automatically follow redirects
* *node.js http/https request options* - Other options are automatically passed through to the underlying node.js http/https request call

### returns object with

* *body* - html response
* *headers*
* *trailers*
* *statusCode*
* *httpVersion*
   

