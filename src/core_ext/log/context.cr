require "log"

struct Log::Context
  def clear
    id = Panopticon.extract
    previous_def
    Panopticon.inject id unless id.nil?
  end
end
