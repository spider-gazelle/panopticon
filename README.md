# Panopticon

_Panopticon_ is a small tool to assist in tracing transactions through distributed systems.

It associates correlation IDs with fibers and handles propagation of these across service boundaries.
Newly created fibers also inherit correlation IDs, allowing tracing across asyncrounous and concurrent tasks.
This enables tracing of transactions throughout the entire system.

When a service receives a request the correlation ID is extracted.
If one does not exist a new ID is generated.
All execution contexts that spawn from this request are tagged with this ID, and in turn distribute to downstream services.
These are available externally via the `X-Correlation-ID` HTTP header and `correlation_id` in the `Log::Context`.

## Usage

```crystal
require "panopticon"
```

That's it.

## Contributing

1. Fork it (<https://github.com/spider-gazelle/panopticon/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kim Burgess](https://github.com/KimBurgess) - creator and maintainer
