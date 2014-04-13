require 'benchmark'

def benchmark(times: 1, input:[], &block)
  GC.start
  (1..times).map do
    GC.disable
    time_taken = Benchmark.realtime { block.call(input) }
    GC.enable
    GC.start

    time_taken
  end.reduce(&:+).to_f / times
end
