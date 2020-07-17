require "fiber"
require "http/request"
require "http/server/context"
require "uuid"
require "./core_ext/**"

module Panopticon
  # Header used for passing the correlation ID between services.
  Header = "X-Corellation-Id"

  # Key used for storing correlations ID's within a `Log::Context`.
  LogKey = :correlation_id

  # TODO: implement xid
  alias Id = UUID

  # Extracts a correlation ID from *request*.
  def self.extract(request : HTTP::Request) : Id?
    if id = request.headers[Header]?
      parse id.first
    end
  end

  # Extract a correlection ID from *fiber*.
  def self.extract(fiber = Fiber.current) : Id?
    if id = fiber.logging_context[LogKey]?
      parse id.to_s
    end
  end

  # Parses *string* into a correlation ID, or `nil` if invalid.
  private def self.parse(string : String) : Id?
    Id.new string
  rescue ArgumentError
    nil
  end

  # Injects a correlection ID into *fiber*.
  #
  # Once injected the ID will continue to be passed to downstream fibers as they
  # are created as well as applied to all outgoing HTTP requests these make.
  def self.inject(id : Id, fiber = Fiber.current) : Nil
    context = fiber.logging_context
    fiber.logging_context = context.extend({correlation_id: id.to_s})
  end

  # Use the supplied *context* to extract any existing identifier and propgate
  # to downstream behaviour.
  def self.attach(context : HTTP::Server::Context) : Nil
    id = extract(request) || Id.new
    inject id
  end

  # Copies the ID linked with *from* to *to*.
  def self.replicate(to : Fiber, from = Fiber.current) : Nil
    extract(from).try do |id|
      inject id, to
    end
  end
end
