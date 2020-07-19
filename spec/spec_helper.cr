require "spec"
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
