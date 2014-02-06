class Hadope::TaskQueue
  extend Forwardable
  include Hadope::ChainableDecorator

  attr_accessor :tasks

  delegate [:clear, :empty?, :push, :shift, :size, :unshift] => :tasks

  def initialize
    @tasks = []
    @logger = Hadope::Logger.get
  end

  chainable def simplify!
    before = @tasks.map(&:statements)
    @tasks = @tasks.reduce [] do |queue, task|
      if queue.empty? then [task]
      else
        *fixed_queue, previous = queue
        case [task.class, previous.class]
        when [Hadope::Map] * 2 then fixed_queue << previous.fuse!(task)
        else                        fixed_queue << previous << task
        end
      end
    end
    @logger.log "Simplify!: Simplified from #{before.inspect}, to #{@tasks.map(&:statements).inspect}."
  end

end
