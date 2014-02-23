module Hadope

  class HybridDevice < Device
    require 'benchmark'

    BENCHMARKS = {
      map:        :map_test_benchmark,
      filter:     :filter_task_benchmark,
      mapfilter:  :mapfilter_task_benchmark,
    }

    def is_hybrid?
      true
    end

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      @ratio = {}
      BENCHMARKS.each { |task, test| @ratio[task] = send test }
      @environment = initialize_hybrid_environment
      super
    end

    def [](type)
      send type.hadope_conversion
    end

    private

    def run_map(task)
      kernel = task.to_kernel
      @logger.log "Executing hybrid map kernel: #{kernel.inspect}"
      run_hybrid_map_task(kernel, task.name, @buffer, *slice_sizes(buffer_length(@buffer), :map))
    end

    TEST_ARRAY_LENGTH = 50
    TEST_DATASET_1    = (1..TEST_ARRAY_LENGTH).to_a

    def map_test_benchmark
      benchmark_action do |device|
        device.pin_integer_dataset(TEST_DATASET_1)
          .map { |x| x * x }[Fixnum]
      end
    end

    def filter_task_benchmark
      benchmark_action do |device|
        device.pin_integer_dataset(TEST_DATASET_1)
          .filter { |x| x % 2 == 0 }[Fixnum]
      end
    end

    def mapfilter_task_benchmark
      benchmark_action do |device|
        device.pin_integer_dataset(TEST_DATASET_1)
          .map { |x| x + 1 }
          .filter { |x| x % 2 == 0 }[Fixnum]
      end
    end

    def individual_devices
      return Hadope::CPU.get, Hadope::GPU.get
    end

    def slice_sizes(length, action)
      ratio = @ratio[action]
      parts = ratio.numerator + ratio.denominator
      num_cpu = ((length / parts.to_f) * ratio.denominator).round
      num_gpu = length - num_cpu
      return num_cpu, num_gpu
    end

    def benchmark_action(&block)
      cpu, gpu = individual_devices

      cpu_time, gpu_time = [cpu, gpu].map do |d|
        Benchmark.realtime do
          block.call(d)
        end
      end

      puts "CPU: #{cpu_time}, GPU: #{gpu_time}"
      puts "CPU_RATIO: #{ratio = Rational(cpu_time, gpu_time).truncate(+1)}"
      ratio
    end

  end

end
