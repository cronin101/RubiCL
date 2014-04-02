require 'asymptotic'
require './rubicl'

seeds = (1..5).map { |x| x * 10000 }

ruby_input = {
  input_seeds: seeds,
  input_function: ->(seed){ (1..seed).to_a }
}
Asymptotic::Graph.plot(3, "Squaring Integers and Filtering Evens",
  "RubiCL library [CPU: Intel i7 dual-core (MBA)] doing the task" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::CPU; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [CPU: Intel i7 dual-core (MBA)] mapping only" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::CPU; array[Int].map { |x| x * x }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [CPU: Intel i7 dual-core (MBA)] filtering only" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::CPU; array[Int].filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "Ruby doing the task" => {
    function: ->(array){ array.map { |x| x * x }.select { |x| x % 2 == 0 } },
  }.merge(ruby_input),

  "Ruby mapping only" => {
    function: ->(array){ array.map { |x| x * x } },
  }.merge(ruby_input),

  "Ruby filtering only" => {
    function: ->(array){ array.select { |x| x % 2 == 0 } },
  }.merge(ruby_input),

)

