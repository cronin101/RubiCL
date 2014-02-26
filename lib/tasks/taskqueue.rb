module Hadope
  class TaskQueue
    extend Forwardable
    include Hadope::ChainableDecorator

    attr_accessor :tasks

    delegate [:clear, :empty?, :push, :shift, :size, :unshift] => :tasks

    def initialize
      @tasks = []
    end

    chainable def simplify!
      before = @tasks.map(&:statements)
      @tasks = @tasks.reduce [] do |queue, task|
        if queue.empty? then [task]
        else
          *fixed_queue, previous = queue
          case [previous.class, task.class]
          when [Hadope::Map] * 2
            fixed_queue << previous.fuse!(task)

          when [Hadope::Map, Hadope::Filter]
            fixed_queue << Hadope::MappingFilter.new(pre_map: previous, filter: task)

          when [Hadope::Filter, Hadope::Map]
            fixed_queue << Hadope::MappingFilter.new(filter: previous, post_map: task)

          when [Hadope::Map, Hadope::MappingFilter]
            fixed_queue << task.pre_fuse!(previous)

          when [Hadope::MappingFilter, Hadope::Map]
            fixed_queue << previous.post_fuse!(task)

          else
            fixed_queue << previous << task
          end
        end
      end
      Logger.log "Simplify!: Simplified from #{before.inspect}, to #{@tasks.map(&:statements).inspect}."
    end

  end
end
