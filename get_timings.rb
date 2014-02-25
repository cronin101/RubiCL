require 'benchmark'
require './hadope'

sizes = (500_000..8_000_000).step(500_000)

# Ruby timings
file = File.open('./timings', 'w')

sizes.each do |size|
  time = (1..5).map do
    sleep 0.2
    Benchmark.realtime do
      (1..size).map { |x| x * x }.select { |x| x % 2 == 0 }
    end
  end.inject(&:+) / 5.0
  file.puts "vanilla_ruby #{size} #{time}"
end

[[Hadope::CPU, 'rubicl_cpu'], [Hadope::GPU, 'rubicl_gpu']].each do |device, description|
  Hadope.opencl_device = device
  (1..100)[Int].map { |x| x + 1 }[Fixnum]
  sizes.each do |size|
    time = (1..5).map do
      sleep 0.2
      Benchmark.realtime do
        (1..size)[Int].map { |x| x * x }.select { |x| x % 2 == 0 }[Fixnum]
      end
    end.inject(&:+) / 5.0
    file.puts "#{description} #{size} #{time.round(3)}"
  end
end
