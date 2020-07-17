require "fiber"

class Fiber
  def initialize(name : String? = nil, &proc : ->)
    previous_def name, &proc
    Panopticon.replicate self
  end
end
