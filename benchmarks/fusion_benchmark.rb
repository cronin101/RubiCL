require 'asymptotic'
require './hadope'

seeds = (8..24)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(pow){ (1..2**pow).to_a }
}
Asymptotic::Graph.plot(1, "Squaring Integers and Filtering Evens",
  "RubiCL library [CPU: Intel i7 dual-core (MBA)] with task fusion" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::CPU; RubiCL::Config::Features.task_fusion = true; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [CPU: Intel i7 dual-core (MBA)] without task fusion" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::CPU; RubiCL::Config::Features.task_fusion = false; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)] with task fusion" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::GPU; RubiCL::Config::Features.task_fusion = true; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)] without task fusion" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::GPU; RubiCL::Config::Features.task_fusion = false; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),
  "Ruby doing the task" => {
    function: ->(array){ array.map { |x| x * x }.select { |x| x % 2 == 0 } },
  }.merge(ruby_input),
)

