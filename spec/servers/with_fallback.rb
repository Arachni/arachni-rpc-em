require_relative 'server'

#$stdout.reopen( '/dev/null', 'w' )
#$stderr.reopen( '/dev/null', 'w' )

opts = rpc_opts.merge(
    port:                7333,
    serializer:          YAML,
    fallback_serializer: Marshal
)

start_server( opts )
