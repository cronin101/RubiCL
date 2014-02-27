require 'spec_helper'

TASK_QUEUE = Hadope::TaskQueue

describe TASK_QUEUE do
  it 'initializes with an empty queue of tasks' do
    queue = TASK_QUEUE.new
    queue.size.should be 0
  end

  context '#simplify!' do
    it 'can be called when there are no tasks' do
      expect { TASK_QUEUE.new.simplify! }.to_not raise_error
    end

    it 'should leave the queued tasks alone when they are not combinable' do
      class SomeTask < Hadope::Task; end
      not_map = SomeTask.new
      map = Hadope::Map.new :footype, :i, ['i + 1']
      map2 = Hadope::Map.new :footype, :i, ['i + 1']

      queue = TASK_QUEUE.new
      expect do
        queue.push not_map
        queue.push map
        queue.push map2
        queue.simplify!
      end.to_not raise_error

      queue.size.should be 2
    end

    it 'can be called when there is only one task' do
      map = Hadope::Map.new(:footype, :i, ['i + 1'])
      queue = TASK_QUEUE.new
      expect do
        queue.push map
        queue.simplify!
      end.to_not raise_error
    end

    context 'with consecutive map tasks' do
      it 'will perform map fusion' do
        map1 = Hadope::Map.new(:footype, :i, ['i = i + 1'])
        map2 = Hadope::Map.new(:footype, :j, ['j = j + 1'])
        queue = TASK_QUEUE.new
        expect do
          queue.push map1
          queue.push map2
          queue.simplify!
        end.to_not raise_error

        queue.size.should be 1
        task = queue.tasks.first
        task.class.should be Hadope::Map
        task.statements.size.should be 3
        task.input_variable.should be :i
        task.output_variable.should be :j
      end
    end

    context 'with a map task followed by a filter task' do
      it 'will perform map-filter fusion' do
        map    = Hadope::Map.new(:footype, :i, ['i = i + 1'])
        filter = Hadope::Filter.new(:footype, :j, ['j > 0'])
        queue = TASK_QUEUE.new
        expect do
          queue.push map
          queue.push filter
          queue.simplify!
        end.to_not raise_error

        queue.size.should be 1
        task = queue.tasks.first
        task.class.should be Hadope::MappingFilter
        task.statements.size.should be 3
        task.input_variable.should be :i
        task.output_variable.should be :i
      end
    end

    context 'with a filter task followed by a map task' do
      it 'will perform map-filter fusion' do
        map    = Hadope::Map.new(:footype, :i, ['i = i + 1'])
        filter = Hadope::Filter.new(:footype, :j, ['j > 0'])
        queue = TASK_QUEUE.new
        expect do
          queue.push filter
          queue.push map
          queue.simplify!
        end.to_not raise_error

        queue.size.should be 1
        task = queue.tasks.first
        task.class.should be Hadope::MappingFilter
        task.statements.size.should be 3
        task.input_variable.should be :j
        task.output_variable.should be :i
      end
    end
  end

  context 'with a map task followed by a mapfilter' do
    it 'will prepend the map statements to the mapfilter' do
      map       = Hadope::Map.new(:bartype, :b, ['b = b * 1'])
      filter    = Hadope::Filter.new(:bartype, :a, ['a > 0'])
      mapfilter = Hadope::MappingFilter.new(pre_map: map, filter: filter)
      pre_map   = Hadope::Map.new(:bartype, :c, ['c = c * 1'])
      queue = TASK_QUEUE.new

      expect do
        queue.push pre_map
        queue.push mapfilter
        queue.simplify!
      end.to_not raise_error

      queue.size.should be 1
      task = queue.tasks.first
      task.class.should be Hadope::MappingFilter
      task.statements.length.should be 5 # 3 tasks with 2 intermediate variable conversions
      task.input_variable.should be :c
    end
  end

  context 'with a mapfilter task followed by a map' do
    it 'will append the map statements to the mapfilter' do
      map       = Hadope::Map.new(:bartype, :b, ['b = b * 1'])
      filter    = Hadope::Filter.new(:bartype, :a, ['a > 0'])
      mapfilter = Hadope::MappingFilter.new(filter: filter, post_map: map)
      post_map   = Hadope::Map.new(:bartype, :c, ['c = c * 1'])
      queue = TASK_QUEUE.new

      expect do
        queue.push mapfilter
        queue.push post_map
        queue.simplify!
      end.to_not raise_error

      queue.size.should be 1
      task = queue.tasks.first
      task.class.should be Hadope::MappingFilter
      task.statements.length.should be 5 # 3 tasks with 2 intermediate variable conversions
    end
  end

end
