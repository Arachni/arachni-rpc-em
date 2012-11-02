# Arachni-RPC EM
<table>
    <tr>
        <th>Version</th>
        <td>0.1.2</td>
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
       <td><a href="mailto:tasos.laskos@gmail.com">Tasos "Zapotek" Laskos</a></td>
    </tr>
    <tr>
        <th>Twitter</th>
        <td><a href="http://twitter.com/Zap0tek">@Zap0tek</a></td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td>2011-2012</td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">3-clause BSD</a></td>
    </tr>
</table>

## Synopsis

Arachni-RPC EM is an implementation of the <a href="http://github.com/Arachni/arachni-rpc">Arachni-RPC</a> protocol using EventMachine and provides both a server and a client. <br/>

## Features

It's capable of:

 - Performing and handling a few thousand requests per second (depending on call size, network conditions and the like).
 - Configurable retry-on-fail for requests.
 - TLS encryption (with peer verification).
 - Asynchronous and synchronous requests.
 - Handling server-side asynchronous calls that require a block (or any method that passes its result to a block instead of returning it).
 - Token-based authentication.
 - Primary and secondary (fallback) serializers -- Server will expect the Client to use the primary serializer,
    if the Request cannot be parsed using the primary one, it will revert to using the fallback to parse the Request and serialize the Response.

## Usage

Check out the files in the <i>examples/</i> directory, they go through everything in great detail.<br/>
The tests under <i>spec/arachni/rpc/</i> cover everything too so they can probably help you out.

## Installation

### Gem

The Gem hasn't been pushed yet, the system is still under development.

### Source

If you want to clone the repository and work with the source code:

    git co git://github.com/arachni/arachni-rpc-em.git
    cd arachni-rpc-em
    rake install

## Running the Specs

    rake spec

## Bug reports/Feature requests
Please send your feedback using Github's issue system at
[http://github.com/arachni/arachni-rpc-em/issues](http://github.com/arachni/arachni-rpc-em/issues).


## License
Arachni-RPC EM is provided under the 3-clause BSD license.<br/>
See the [LICENSE](file.LICENSE.html) file for more information.

