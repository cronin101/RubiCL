class Hadope::TaskQueue
  extend Forwardable

  attr_accessor :tasks

  delegate [:clear, :empty?, :push, :shift, :size] => :tasks

  def initialize
    @tasks = []
    @logger = Hadope::Logger.get
  end

  def simplify!
    before = @tasks.map(&:statements)
    @tasks = @tasks.inject [] do |queue, task|
      if queue.empty?
          result = [task]
      else
        *fixed_queue, previous = queue

        case [task.class, previous.class]
        when [Hadope::Map]*2
          result = fixed_queue << previous.fuse!(task)
        else
          result = fixed_queue << previous << task
        end
      end
      result
    end
    after = @tasks.map(&:statements)

    @logger.log "Simplify!: Simplified from #{before.inspect}, to #{after.inspect}."

    self
  end

end
