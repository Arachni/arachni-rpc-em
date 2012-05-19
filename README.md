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
       <td><a href="mailto:tasos.laskos@gmail.com">Tasos</a> "<a href="mailto:zapotek@segfault.gr">Zapotek</a>" <a href="mailto:tasos.laskos@gmail.com">Laskos</a></td>
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
It is under development and will ultimately form the basis for <a href="http://arachni.segfault.gr">Arachni</a>'s Grid infrastructure.

## Features

It's capable of:

 - performing and handling a few thousand requests per second (depending on call size, network conditions and the like)
 - TLS encryption (with peer verification)
 - asynchronous and synchronous requests
 - handling server-side asynchronous calls that require a block (or any method that requires a block in general)
 - token-based authentication

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

