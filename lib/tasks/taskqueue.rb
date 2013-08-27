class Hadope::TaskQueue
  extend Forwardable

  attr_accessor :tasks

  delegate [:clear, :push, :shift, :size] => :tasks

  def initialize
    @tasks = []
  end

  def simplify
    @tasks.inject [] do |queue, task|
      if queue.empty?
        [task]
      else
        *fixed_queue, previous_task = queue

        if previous_task.class == task.class
          conversion =  case task
                        when Hadope::Map
                          previous_task.set_output_name task.input_name
                          ["#{task.input_name} = #{previous_task.input_name}"]
                        else
                          []
                        end

          fixed_queue << previous_task.add_statements(conversion + task.statements)
        else
          fixed_queue << previous_task << task
        end
      end
    end
  end

  def simplify!
    @tasks = simplify
  end

end