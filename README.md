##Use OpenCL to speed up parallel computations in Ruby!

####Got a lot of numbers lying around?
```ruby
input = (1..10_000_000).to_a
```
####This takes 4.94s:
```ruby
ruby = Benchmark.realtime {
  last = input
    .map { |i| i + 1 }
    .map { |i| i + 1 }
    .map { |i| i * 2 }
    .map { |i| i / 2 }
    .map { |i| i - 1 }
    .map { |i| i - 1 }.last
}
```

####This takes 0.26s:
```ruby
require './rubicl'
Hadope::set_device Hadope::CPU

opencl = Benchmark.realtime {
  last = input[Int]
    .map { |i| i + 1 }
    .map { |i| i + 1 }
    .map { |i| i * 2 }
    .map { |i| i / 2 }
    .map { |i| i - 1 }
    .map { |i| i - 1 }[Fixnum].last
}
```

```ruby
"Ruby: #{ruby.inspect}, OpenCL: #{opencl.inspect}"
# => Ruby: 4.937122, OpenCL: 0.262981
```
