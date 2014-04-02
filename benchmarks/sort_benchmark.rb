require 'asymptotic'
require './rubicl'

seeds = (10..22)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(pow){ (1..2**pow).to_a.shuffle }
}
Asymptotic::Graph.plot(3, "Sorting Integers",
  "RubiCL library [CPU: Intel i7 dual-core (MBA)] host_mem = t" => {
    function: ->(array){ RubiCL::Config::Features.use_host_mem = true; RubiCL.opencl_device = RubiCL::CPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [CPU: Intel i7 dual-core (MBA)] host_mem = f" => {
    function: ->(array){ RubiCL::Config::Features.use_host_mem = false; RubiCL.opencl_device = RubiCL::CPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)] host_mem = t" => {
    function: ->(array){ RubiCL::Config::Features.use_host_mem = true; RubiCL.opencl_device = RubiCL::GPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)] host_mem = f" => {
    function: ->(array){ RubiCL::Config::Features.use_host_mem = false; RubiCL.opencl_device = RubiCL::GPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),


  "Ruby doing the task" => {
    function: ->(array){ array.sort },
  }.merge(ruby_input),
)

