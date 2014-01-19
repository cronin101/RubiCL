class Hadope::HybridDevice
  require 'benchmark'

  BENCHMARKS = {
    map:        :map_test_benchmark,
    filter:     :filter_task_benchmark,
    mapfilter:  :mapfilter_task_benchmark,
  }

  class << self
    attr_accessor :singleton

    def get
      @singleton ||= new
    end
  end

  def initialize
    @ratio = {}
    BENCHMARKS.each do |task, test|
      @ratio[task] = send test
    end
  end

  def [](type)
    send type.hadope_conversion
  end

  def pin_integer_dataset(array)
    ratio = @ratio[:mapfilter]
    parts = ratio.numerator + ratio.denominator
    num_cpu = ((array.length / parts.to_f) * ratio.denominator).round
    num_gpu = array.length - num_cpu

    puts "NCPU: #{num_cpu}, NGPU: #{num_gpu}"

    cpu, gpu = get_hybrid_devices
    cpu.pin_integer_range(array, 0, num_cpu - 1)
    gpu.pin_integer_range(array, num_cpu, array.length - 1)

    self
  end

  def retrieve_pinned_integer_dataset
    cpu, gpu = get_hybrid_devices
    [cpu, gpu].each { |d| d.instance_eval { run_tasks } }
    cpu = cpu.instance_eval { retrieve_pinned_integer_dataset_from_buffer @buffer }
    gpu = gpu.instance_eval { retrieve_pinned_integer_dataset_from_buffer @buffer }
    cpu.concat gpu
  end

  TEST_ARRAY_LENGTH = 50_000_000
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

  private

  def benchmark_action(&block)
    cpu, gpu = get_hybrid_devices

    cpu_time, gpu_time = [cpu, gpu].map do |d|
      Benchmark.realtime do
        block.call(d)
      end
    end

    puts "CPU: #{cpu_time}, GPU: #{gpu_time}"
    puts "CPU_RATIO: #{ratio = Rational(cpu_time, gpu_time).truncate(+1)}"
    ratio
  end

  def get_hybrid_devices
    return Hadope::CPU.get, Hadope::GPU.get
  end

end
