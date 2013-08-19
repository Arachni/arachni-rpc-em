# ChangeLog

## Version 0.2.1 _(Under development)_

- Added `Client#close` -- Empties the connection pool and closes all connections.

## Version 0.2 _(June 23, 2013)_

- YAML engine no longer forced to _Syck_.
- Added support for UNIX domain sockets.
- `Client`
    - Moved connection handler to its own class file.
    - Updated to reuse connections whenever possible.
    - Maintains an adjustable-sized connection pool.
        - Uses a single connection by default.
- `Server`
    - Moved connection handler to its own class file.
    - Removed connection inactivity timeout.
- Cleaned up RSpec tests.
- Added Bundler files.

## Version 0.1.3 _(April 15, 2013)_

- Stopped client callbacks from being deferred.
- Server now supports a fallback serializer to allow clients to use a secondary
    serializer if they so choose.
- Client request-retry strategy tweaked to be more resilient.

## Version 0.1.2

- Code cleanup.
- Client retries on Errno::ECONNREFUSED.
