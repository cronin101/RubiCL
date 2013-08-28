class Hadope::TaskQueue
  extend Forwardable

  attr_accessor :tasks

  delegate [:clear, :empty?, :push, :shift, :size] => :tasks

  def initialize
    @tasks = []
  end

  def simplify!
    @tasks = @tasks.inject [] do |queue, task|
      if queue.empty?
        result = [task]
      else
        *fixed_queue, previous_task = queue

        if previous_task.class == task.class
          conversion =  case task
                        when Hadope::Map
                          if previous_task.output_variable == task.input_variable
                            [] # No variable pipelining required!
                          else
                            pipeline_variable = previous_task.output_variable
                            previous_task.set_output_variable task.output_variable
                            previous_task.add_variables task.input_variable
                            ["#{task.input_variable} = #{pipeline_variable} /* Pipeline */"]
                          end
                        else
                          raise "Task type not current supported"
                        end

          result = fixed_queue << previous_task.add_statements(conversion + task.statements)
        else
          result = fixed_queue << previous_task << task
        end

      end
      result
    end

    self
  end

end
