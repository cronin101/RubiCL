require 'asymptotic'
require './hadope'

seeds = (10..19)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(x){ sleep 0.2 and (1..x*6000).to_a }
}

Hadope.opencl_device = Hadope::CPU
(1..100)[Int].map { |x| x + 1 }[Fixnum]
Hadope.opencl_device = Hadope::GPU
(1..100)[Int].map { |x| x + 1 }[Fixnum]

Asymptotic::Graph.plot(1, "Sparse Filtering on Floating-point Numbers",
=begin
  "RubiCL library [GPU: Intel HD5000 (MBA)]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::GPU; array[Double].map { |x| x + 1.0 }[Float] }
  }.merge(ruby_input),
=end
  "RubiCL library [Hybrid]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::HybridDevice; array[Int].select { |x| x.even? }[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [CPU: Intel i7 dual-core (MBA)]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::CPU; array[Int].select { |x| x.even? }[Fixnum] }
  }.merge(ruby_input),

  "Ruby doing the task" => {
    function: ->(array){ array.select { |x| x.even? } }
  }.merge(ruby_input),
)

