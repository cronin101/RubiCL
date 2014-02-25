require 'asymptotic'
require './hadope'

seeds = (10..22)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(pow){ (1..2**pow).to_a.shuffle }
}
Asymptotic::Graph.plot(3, "Sorting Integers",
  "RubiCL library [CPU: Intel i7 dual-core (MBA)] host_mem = t" => {
    function: ->(array){ Hadope::Config::Features.use_host_mem = true; Hadope.opencl_device = Hadope::CPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [CPU: Intel i7 dual-core (MBA)] host_mem = f" => {
    function: ->(array){ Hadope::Config::Features.use_host_mem = false; Hadope.opencl_device = Hadope::CPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)] host_mem = t" => {
    function: ->(array){ Hadope::Config::Features.use_host_mem = true; Hadope.opencl_device = Hadope::GPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),

  "RubiCL library [GPU: Intel HD5000 (MBA)] host_mem = f" => {
    function: ->(array){ Hadope::Config::Features.use_host_mem = false; Hadope.opencl_device = Hadope::GPU; array[Int].sort[Fixnum] }
  }.merge(ruby_input),


  "Ruby doing the task" => {
    function: ->(array){ array.sort },
  }.merge(ruby_input),
)

