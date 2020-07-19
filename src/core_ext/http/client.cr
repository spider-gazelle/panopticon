require "http/client"

class HTTP::Client
  private def send_request(request)
    Panopticon.propagate request
    previous_def request
  end
end
