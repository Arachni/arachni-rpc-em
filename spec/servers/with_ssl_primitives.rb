require_relative 'server'

$stdout.reopen( '/dev/null', 'w' )
$stderr.reopen( '/dev/null', 'w' )

cwd = File.expand_path( File.dirname( __FILE__ ) )
opts = rpc_opts.merge(
    port:       7332,
    ssl_ca:     cwd + '/../pems/cacert.pem',
    ssl_pkey:   cwd + '/../pems/server/key.pem',
    ssl_cert:   cwd + '/../pems/server/cert.pem'
)

start_server( opts )
