require "fiber"
require "http/request"
require "http/server/context"
require "uuid"
require "./core_ext/**"

module Panopticon
  # Header used for passing the correlation ID between services.
  HTTPHeader = "X-Correlation-ID"

  # Key used for storing correlation IDs within a `Log::Context`.
  LogKey = :correlation_id

  private alias ID = String

  # Generates a new correlation ID.
  def self.generate_id : ID
    # TODO: implement xid
    UUID.random.to_s
  end

  # Extracts a correlation ID from *request*.
  def self.extract(request : HTTP::Request) : ID?
    request.headers[HTTPHeader]?
  end

  # Extracts a correlation ID from *fiber*.
  def self.extract(fiber = Fiber.current) : ID?
    fiber.logging_context[LogKey]?.try &.as_s
  end

  # Injects a correlation ID into *fiber*.
  #
  # Once injected the ID will continue to be passed to downstream fibers as they
  # are created as well as applied to all outgoing HTTP requests these make.
  def self.inject(id : ID, fiber = Fiber.current) : Nil
    context = fiber.logging_context
    fiber.logging_context = context.extend({{ "{#{LogKey.id}: id.to_s}".id }})
  end

  # Use the supplied *context* to extract any existing ID and propagate to
  # downstream contexts.
  def self.attach(context : HTTP::Server::Context) : Nil
    id = extract(request) || generate_id
    inject id
  end

  # Copies the ID linked with *from* to *to*.
  def self.replicate(to : Fiber, from = Fiber.current) : Nil
    extract(from).try do |id|
      inject id, to
    end
  end
end
