```ruby
#!/usr/bin/env ruby
require './hadope'
require 'benchmark'

puts "Problem, mapping several numerical operations to a large Array"

Hadope::set_device Hadope::CPU
Hadope::Logger.get.quiet_mode

ruby_input = (1..10_000_000).to_a
input = (1..10_000_000).to_a

ruby = Benchmark.realtime {
  last = ruby_input
    .map { |i| i + 1 }
    .map { |i| i + 1 }
    .map { |i| i * 2 }
    .map { |i| i / 2 }
    .map { |i| i - 1 }
    .map { |i| i - 1 }.last
  puts "Ruby says result is #{last}"
}

opencl = Benchmark.realtime {
  last = input[Integer]
    .map(i:'i + 1')
    .map(i:'i + 1')
    .map(i:'i * 2')
    .map(i:'i / 2')
    .map(i:'i - 1')
    .map(i:'i - 1')[Fixnum].last
  puts "OpenCL says result is #{last}"
}

puts "Ruby: #{ruby.inspect}, OpenCL: #{opencl.inspect}"

=begin
λ  HaDope git:(master) ✗ ./Benchmark.rb
Problem, mapping several numerical operations to a large Array
Ruby says result is 10000000
OpenCL says result is 10000000
Ruby: 4.992017, OpenCL: 0.318413
=end
```
