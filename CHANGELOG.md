# ChangeLog

## Version 0.1.3 (_Under development_)

- Stopped client callbacks from being deferred.
- Server now supports a fallback serializer to allow clients to use a secondary serializer if they so choose.
- Client request-retry strategy tweaked to be more resilient.

## Version 0.1.2

- Code cleanup.
- Client retries on Errno::ECONNREFUSED.
