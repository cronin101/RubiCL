require 'asymptotic'
require './hadope'

seeds = (25..27)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(pow){ (1..2**pow).to_a }
}
Asymptotic::Graph.plot(1, "Mapping on Integers",
  "RubiCL library [CPU: Intel i7 dual-core (MBA)]" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::CPU; array[Int].map { |x| x * x }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)]" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::GPU; array[Int].map { |x| x * x }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [Task Split Across CPU and GPU]" => {
    function: ->(array){ RubiCL.opencl_device = RubiCL::HybridDevice; array[Int].map { |x| x * x }[Fixnum] }
  }.merge(ruby_input),

=begin
  "Ruby doing the task" => {
    function: ->(array){ array.map { |x| x + 1 } },
  }.merge(ruby_input),
=end
)

