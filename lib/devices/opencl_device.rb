class HaDope
  module DeviceMethods

    def load(dataset_name)
      clear_cache

      dataset = HaDope::DataSet[dataset_name]

      buffer_time = Benchmark.realtime do
        @membuffer = create_memory_buffer(dataset.data[:size], dataset.type.to_s)
      end
      puts "Buffer Time: #{buffer_time}"

      input_time = Benchmark.realtime do
        load_int_dataset(dataset.data[:values], @membuffer)
      end
      puts "Dataset Input Time: #{input_time}"

      self
    end

    def fp_map(*tasks)
      tasks.each { |task| do_fp_map(task) }
      self
    end

    def fp_filter(*tasks)
      tasks.each { |task| do_fp_filter(task) }
      self
    end

    def presence_array
      output_time = Benchmark.realtime do
        @presence_array ||= retrieve_int_dataset(@presence_buffer)
      end
      puts "Dataset Output Time: #{output_time}"

      @presence_array
    end

    def output
      output_time = Benchmark.realtime do
        @output ||= retrieve_int_dataset(@membuffer)
      end
      puts "Dataset Output Time: #{output_time}"

      @output
    end

    def clean
      clean_used_resources(@membuffer)
    end

    private
    def clear_cache
      @output, @presence_array = [nil]*2
    end

    def do_fp_map(task_name)
      clear_cache

      map_task = HaDope::Functional::Map[task_name]
      kernel = map_task.kernel

      map_time = Benchmark.realtime do
        run_map_task(kernel, kernel.length, map_task.name.to_s, @membuffer)
      end
      puts "#{task_name} Time: #{map_time}"
    end

    def do_fp_filter(task_name)
      clear_cache

      filter_task = HaDope::Functional::Filter[task_name]
      kernel = filter_task.kernel

      filter_time = Benchmark.realtime do
        @presence_buffer = run_filter_task(kernel, kernel.length, filter_task.name.to_s, @membuffer)
      end
      puts "#{task_name} Time: #{filter_time}"
    end

  end
end
