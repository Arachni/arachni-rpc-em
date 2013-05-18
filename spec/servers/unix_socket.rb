require_relative 'server'

$stdout.reopen( '/dev/null', 'w' )
$stderr.reopen( '/dev/null', 'w' )

opts = rpc_opts.merge(
    socket: '/tmp/arachni-rpc-em-test',
    serializer:          Marshal
)

start_server( opts )
