require "log"

struct Log::Context
  def clear
    id = Panopticon.extract Fiber.current
    previous_def
    Panopticon.inject id, Fiber.current unless id.nil?
  end
end
