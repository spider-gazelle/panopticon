require "fiber"

class Fiber
  def initialize(name : String? = nil, &proc : ->)
    previous_def name, &proc
    Panopticon.propagate self
  end
end
