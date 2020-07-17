require "http/server/context"

class HTTP::Server::Context
  # :nodoc:
  def initialize(request : Request, response : Response)
    previous_def request, response
    Panopticon.attach self
  end
end
