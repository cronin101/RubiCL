require 'benchmark'
require './rubicl'

sizes = (1_000_000..15_000_000).step(2_000_000)

# Ruby timings
file = File.open('./timings', 'w')

sizes.each do |size|
  time = (1..8).map do
    sleep 0.1
    Benchmark.realtime do
      (1..size).map { |x| x * x }.select { |x| x % 2 == 0 }
    end
  end.inject(&:+) / 8.0
  file.puts "vanilla_ruby #{size} #{time.round(3)}"
end

[[RubiCL::CPU, 'rubicl_cpu'], [RubiCL::GPU, 'rubicl_gpu']].each do |device, description|
  RubiCL.opencl_device = device
  (1..100)[Int].map { |x| x + 1 }[Fixnum]
  sizes.each do |size|
    time = (1..8).map do
      sleep 0.2
      Benchmark.realtime do
        (1..size)[Int].map { |x| x * x }.select { |x| x % 2 == 0 }[Fixnum]
      end
    end.inject(&:+) / 8.0
    file.puts "#{description} #{size} #{time.round(3)}"
  end
end
