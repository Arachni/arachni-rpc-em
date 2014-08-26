# Defunct

This project is no longer maintained nor used by Arachni, it has been substituted by
[Arachni-RPC](http://github.com/Arachni/arachni-rpc).

# Arachni-RPC EM

<table>
    <tr>
        <th>Version</th>
        <td>0.2</td>
    </tr>
    <tr>
        <th>Github page</th>
        <td><a href="http://github.com/Arachni/arachni-rpc-em">http://github.com/Arachni/arachni-rpc-em</a></td>
     <tr/>
    <tr>
        <th>Code Documentation</th>
        <td><a href="http://rubydoc.info/github/Arachni/arachni-rpc-em/">http://rubydoc.info/github/Arachni/arachni-rpc-em/</a></td>
    </tr>
    <tr>
       <th>Author</th>
       <td><a href="mailto:tasos.laskos@arachni-scanner.com">Tasos "Zapotek" Laskos</a> (<a href="http://twitter.com/Zap0tek">@Zap0tek</a>)</td>
    </tr>
    <tr>
        <th>Twitter</th>
        <td><a href="http://twitter.com/ArachniScanner">@ArachniScanner</a></td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td>2011-2013</td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">3-clause BSD</a></td>
    </tr>
</table>

## Synopsis

Arachni-RPC EM is an implementation of the <a href="http://github.com/Arachni/arachni-rpc">Arachni-RPC</a>
protocol using EventMachine and provides both a server and a client. <br/>

## Features

It's capable of:

- Performing and handling a few thousand requests per second (depending on call
    size, network conditions and the like).
- Operating over TCP/IP and UNIX domain sockets.
- Configurable retry-on-failure for requests.
- Keep-alive and connection re-use.
- TLS encryption (with peer verification).
- Asynchronous and synchronous requests.
- Handling server-side asynchronous calls that require a block (or any method
    that passes its result to a block instead of returning it).
- Token-based authentication.
- Primary and secondary/fallback serializers
    - Server will expect the Client to use the primary serializer, if the Request
        cannot be parsed using the primary one, it will revert to using the
        fallback to parse the Request and serialize the Response.

## Usage

The files in the `examples/` directory go through everything in great detail.
Also, the tests under `spec/arachni/rpc/` cover everything too so they can
provide you with hints.

## Installation

### Gem

    gem install arachni-rpc-em

### Source

If you want to clone the repository and work with the source code:

    git co git://github.com/arachni/arachni-rpc-em.git
    cd arachni-rpc-em
    bundle install

## Running the Specs

    bundle exec rake spec

**Warning**: Some of the test cases include stress-testing, don't be alarmed
when RAM usage hits 5GB and CPU utilization hits 100%.

## Bug reports/Feature requests

Please send your feedback using GitHub's issue system at
[http://github.com/arachni/arachni-rpc-em/issues](http://github.com/arachni/arachni-rpc-em/issues).


## License

Arachni-RPC EM is provided under the 3-clause BSD license.<br/>
See the [LICENSE](file.LICENSE.html) file for more information.
