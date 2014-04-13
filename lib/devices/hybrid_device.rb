module RubiCL
  class HybridDevice < Device
    require 'benchmark'

    BENCHMARKS = {
      map:        :map_test_benchmark,
      filter:     :filter_task_benchmark,
#      mapfilter:  :mapfilter_task_benchmark,
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
      send type.rubicl_conversion
    end

    private

    def run_map(task)
      kernel = task.to_kernel
      @logger.log "Executing hybrid map kernel: #{kernel.inspect}"
      run_hybrid_map_task(kernel, task.name, @buffer, *slice_sizes(buffer_length(@buffer), :map))
    end

    def run_filter(task)
      kernel = task.to_kernel
      @logger.log "Executing hybrid filter kernel: #{kernel.inspect}"
      cpu_scan_kernel = Scan.new(type: :int, operator: :+, elim_conflicts: false).to_kernel
      gpu_scan_kernel = Scan.new(type: :int, operator: :+, elim_conflicts: true).to_kernel
      scan_kernels = [cpu_scan_kernel, gpu_scan_kernel]
      run_hybrid_filter_task(kernel, task.name, *scan_kernels, @buffer,
                             *slice_sizes(buffer_length(@buffer), :filter))
    end

    TEST_ARRAY_LENGTH = 5_000_000
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
      [RubiCL::CPU.get, RubiCL::GPU.get]
    end

    def slice_sizes(length, action)
      ratio = @ratio[action]
      parts = ratio.numerator + ratio.denominator
      num_cpu = ((length / parts.to_f) * ratio.denominator).round
      num_gpu = length - num_cpu
      [num_cpu, num_gpu]
    end

    def benchmark_action(&block)
      cpu, gpu = individual_devices

      cpu_time, gpu_time = [cpu, gpu].map do |d|
        Benchmark.realtime do
          block.call(d)
        end
      end
      Rational(cpu_time, gpu_time).truncate(+1)
    end
  end
end
