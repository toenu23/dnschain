###

dnschain
http://dnschain.net

Copyright (c) 2014 okTurtles Foundation

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

###

BlockchainResolver = require '../blockchain.coffee'

module.exports = (dnschain) ->
    # expose these into our namespace
    for k of dnschain.globals
        eval "var #{k} = dnschain.globals.#{k};"

    class KeyidResolver extends BlockchainResolver
        constructor: (@dnschain) ->
            @log = gNewLogger 'BDNS'
            @tld = 'p2p'
            @name = 'keyid'

        config: ->
            @log.debug "Loading KeyidResolver..."
            
            get = gConf.bdns.get
            endpoint = get('rpc:httpd_endpoint')?.split ':'
            if endpoint?
                [host, port] = [endpoint[0], parseInt endpoint[1]]
                @peer = rpc.Client.$create port, host, get('rpc:rpc_user'), get('rpc:rpc_password')
                gErr "rpc $create #{@name}" unless @peer
                @log.info "rpc to bitshares_client on: %s:%d/rpc", host, port
                return @
            else
                @log.info "#{@name} disabled. (config.json not found)"
                return

        shutdown: ->
            @log.debug 'shutting down!'
            # @peer.end() # TODO: fix this!

        resolve: (path, options, cb) ->
            @log.debug gLineInfo("#{@name} resolve"), {path:path}
            @peer.call 'dotp2p_show', [path], path:'/rpc', (err, result) ->
                return (cb err, result) if err
                if _.isString result
                    try
                        result.value = JSON.parse result
                    catch e
                        err = e
                else if not _.isObject result
                    @log.warn gLineInfo('type not string or object!'), {json: result, type: typeof(result)}
                    result.value = {}
                cb err,result
