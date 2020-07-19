require "spec"
require "http/server"
require "uri"
require "../src/panopticon"

# Runs *block* in a new fiber synchronously.
macro in_fiber(&block)
  %ch = Channel(Nil | Exception).new
  spawn do
    begin
      {{block.body}}
      %ch.send nil
    rescue e
      %ch.send e
    end
  end
  %err = %ch.receive
  raise %err if %err
end

# Provides a HTTP server that will respond to a single request, then close.
def with_server(&block : HTTP::Handler::HandlerProc) : URI
  ch = Channel(Nil).new

  server = HTTP::Server.new do |context|
    block.call context
    spawn { ch.send nil }
  end

  sock = server.bind_unused_port

  spawn { server.listen }
  spawn { ch.receive; server.close }

  URI.new scheme: "http", host: sock.address, port: sock.port
end
