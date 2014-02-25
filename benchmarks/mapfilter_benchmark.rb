require 'asymptotic'
require './hadope'

seeds = (8..20)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(pow){ (1..2**pow).to_a }
}
Asymptotic::Graph.plot(3, "Squaring Integers and Filtering Evens",
  "RubiCL library [CPU: Intel i7 dual-core (MBA)]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::CPU; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::GPU; array[Int].map { |x| x * x }.filter{|x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [Task Split Across CPU and GPU]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::HybridDevice; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "Ruby doing the task" => {
    function: ->(array){ array.map { |x| x + x }.select { |x| x % 2 == 0 } },
  }.merge(ruby_input),
)

