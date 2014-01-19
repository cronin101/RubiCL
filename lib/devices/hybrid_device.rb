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

  TEST_ARRAY_LENGTH = 50_000_000
  TEST_DATASET_1    = (1..TEST_ARRAY_LENGTH).to_a

  def map_test_benchmark
    cpu, gpu = get_hybrid_devices

    cpu_time, gpu_time = [cpu, gpu].map do |d|
      Benchmark.realtime do
        d.pin_integer_dataset(TEST_DATASET_1)
          .map { |x| x * x }[Fixnum]
      end
    end

    puts "CPU: #{cpu_time}, GPU: #{gpu_time}"
    puts "CPU_RATIO: #{ratio = Rational(cpu_time, gpu_time).truncate(+1)}"
    ratio
  end

  def filter_task_benchmark
    cpu, gpu = get_hybrid_devices

    cpu_time, gpu_time = [cpu, gpu].map do |d|
      Benchmark.realtime do
        d.pin_integer_dataset(TEST_DATASET_1)
          .filter { |x| x % 2 == 0 }[Fixnum]
      end
    end

    puts "CPU: #{cpu_time}, GPU: #{gpu_time}"
    puts "CPU_RATIO: #{ratio = Rational(cpu_time, gpu_time).truncate(+1)}"
    ratio
  end

  def mapfilter_task_benchmark
    cpu, gpu = get_hybrid_devices

    cpu_time, gpu_time = [cpu, gpu].map do |d|
      Benchmark.realtime do
        d.pin_integer_dataset(TEST_DATASET_1)
          .map { |x| x + 1 }
          .filter { |x| x % 2 == 0 }[Fixnum]
      end
    end

    puts "CPU: #{cpu_time}, GPU: #{gpu_time}"
    puts "CPU_RATIO: #{ratio = Rational(cpu_time, gpu_time).truncate(+1)}"
    ratio
  end

  private

  def get_hybrid_devices
    return Hadope::CPU.get, Hadope::GPU.get
  end

end
