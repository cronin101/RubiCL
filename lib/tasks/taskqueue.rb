module RubiCL
  class TaskQueue
    extend Forwardable
    include RubiCL::ChainableDecorator

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
          when ([RubiCL::Map] * 2), ([RubiCL::Filter] * 2)
            fixed_queue << previous.fuse!(task)

          when [RubiCL::Map, RubiCL::Filter]
            fixed_queue << RubiCL::MappingFilter.new(pre_map: previous, filter: task)

          when [RubiCL::Filter, RubiCL::Map]
            fixed_queue << RubiCL::MappingFilter.new(filter: previous, post_map: task)

          when [RubiCL::Map, RubiCL::MappingFilter]
            fixed_queue << task.pre_fuse!(previous)

          when [RubiCL::MappingFilter, RubiCL::Map]
            fixed_queue << previous.post_fuse!(task)

          when [RubiCL::MappingFilter, RubiCL::Filter]
            if previous.has_post_map?
              fixed_queue << previous << task
            else
              fixed_queue << previous.filter_fuse!(task)
            end

          else
            fixed_queue << previous << task
          end
        end
      end
      Logger.log "Simplify!: Simplified from #{before.inspect}, to #{@tasks.map(&:statements).inspect}."
    end

  end
end
