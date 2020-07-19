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

  alias ID = String

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
  def self.extract(fiber : Fiber) : ID?
    fiber.logging_context[LogKey]?.try &.as_s
  end

  # Provide an ID for the current execution context.
  def self.id : ID
    id? || self.id=(generate_id)
  end

  # Provides the current correlation ID, or `nil` if tracking is not active.
  def self.id? : ID?
    extract Fiber.current
  end

  # Sets the ID for the current execution context.
  def self.id=(id : ID) : ID
    inject id, Fiber.current
  end

  # Injects a correlation ID into *fiber*.
  #
  # Once injected the ID will continue to be passed to downstream fibers as they
  # are created as well as applied to all outgoing HTTP requests these make.
  def self.inject(id : ID, fiber : Fiber) : ID
    context = fiber.logging_context
    fiber.logging_context = context.extend({{ "{#{LogKey.id}: id.to_s}".id }})
    id
  end

  # Use the supplied *context* to extract any existing ID and propagate to
  # downstream contexts.
  def self.attach(context : HTTP::Server::Context) : ID
    self.id = extract(context.request) || generate_id
  end

  # Copies the ID linked with *from* to *to*.
  def self.replicate(to : Fiber, from = Fiber.current) : ID?
    extract(from).try do |id|
      inject id, to
    end
  end
end
