# ChangeLog

## Version 0.2dev _(Under development)_

- YAML engine no longer forced to _Syck_.
- Moved connection handlers to their own class files.
- `Client`
    - Updated to reuse connections whenever possible.
    - Maintains an adjustable-sized connection pool.
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
