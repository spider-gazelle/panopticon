# panopticon

Panopticon is a small tool to assist in tracing transactions through distributed systems.

It creates or extracts a `X-Correlation-Id` header and applies this to any outgoing HTTP requests made from the same Fiber, or a child Fibers.
Correlation ID are also available as part of the current fiber's logging context.
This is also replicated to any new fibers to maintain references across asyncronous tasks associated with the original event.

## Usage

```crystal
require "panopticon"
```

That's it!

## Contributing

1. Fork it (<https://github.com/spider-gazelle/panopticon/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kim Burgess](https://github.com/KimBurgess) - creator and maintainer
