###

dnschain
http://dnschain.net

Copyright (c) 2014 okTurtles Foundation

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

###

module.exports = (dnschain) ->
    # expose these into our namespace
    for k of dnschain.globals
        eval "var #{k} = dnschain.globals.#{k};"

    class HTTPServer
        constructor: (@dnschain) ->
            # @log = @dnschain.log.child server: "HTTP"
            @log = gNewLogger 'HTTP'
            @log.debug "Loading HTTPServer..."

            @server = http.createServer(@callback.bind(@)) or gErr "http create"
            @server.on 'error', (err) -> gErr err
            @server.on 'sockegError', (err) -> gErr err
            @server.listen gConf.get('http:port'), gConf.get('http:host') or gErr "http listen"
            # @server.listen gConf.get 'http:port') or gErr "http listen"
            @log.info 'started HTTP', gConf.get 'http'

        shutdown: ->
            @log.debug 'shutting down!'
            @server.close()

        # TODO: send a signed header proving the authenticity of our answer

        callback: (req, res) ->
            path = S(url.parse(req.url).pathname).chompLeft('/').s
            options = url.parse(req.url, true).query
            @log.debug gLineInfo('request'), {path:path, options:options, url:req.url}

            notFound = =>
                res.writeHead 404,  'Content-Type': 'text/plain'
                res.write "Not Found: #{path}"
                res.end()

            resolverName = S(req.headers.host).chompRight('.dns').s
            resolver =
                if @dnschain.chains[resolverName]?
                    @dnschain.chains[resolverName]
                else
                    @log.warn gLineInfo "unknown host type: #{req.headers.host} -- defaulting to namecoin.dns!"
                    @dnschain.chains['namecoin']

            resolver.resolve path, options, (err,result) =>
                if err
                    @log.debug gLineInfo('resolver failed'), {err:err}
                    return notFound()
                else
                    res.writeHead 200, 'Content-Type': 'application/json'
                    @log.debug gLineInfo('cb|resolve'), {path:path, result:result}
                    res.write @dnschain.chains[resolver].toJSONstr result
                    res.end()
