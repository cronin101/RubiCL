class Hadope::TaskQueue
  extend Forwardable

  attr_accessor :tasks

  delegate [:clear, :size] => :tasks

  def initialize
    @tasks = []
  end

end
