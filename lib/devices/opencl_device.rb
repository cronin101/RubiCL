class HaDope
  module DeviceMethods

    def load(dataset_name)
      dataset = HaDope::DataSet[dataset_name]
      puts "Buffer Time: #{Benchmark.realtime{ @membuffer = create_memory_buffer(dataset.data[:size], dataset.type.to_s) }}"
      puts "Dataset Input Time: #{Benchmark.realtime{ load_int_dataset(dataset.data[:values], @membuffer) }}"
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
      retrieve_int_dataset(@presence_array)
    end

    def output
      dataset = []
      puts "Dataset Output Time: #{Benchmark.realtime{ dataset = retrieve_int_dataset(@membuffer) }}"
      dataset
    end

    def clean
      clean_used_resources(@membuffer)
    end

    private

    def do_fp_map(task_name)
      map_task = HaDope::Functional::Map[task_name]
      kernel = map_task.kernel
      puts "#{task_name} Time: #{Benchmark.realtime{ run_map_task(kernel, kernel.length, map_task.name.to_s, @membuffer) }}"
    end

    def do_fp_filter(task_name)
      filter_task = HaDope::Functional::Filter[task_name]
      kernel = filter_task.kernel
      puts "#{task_name} Time: #{Benchmark.realtime{ @presence_array = run_filter_task(kernel, kernel.length, filter_task.name.to_s, @membuffer) }}"
    end

  end
end
