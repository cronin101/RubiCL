require 'asymptotic'
require './rubicl'

seeds = (8..22)

ruby_input = {
  input_seeds: seeds,
  input_function: ->(pow) { (1..2**pow).to_a }
}
Asymptotic::Graph.plot(1, 'Squaring Integers and Filtering Evens',
                       'RubiCL library [CPU: Intel i7 dual-core (MBA)] with use host ptr' => {
                         function: ->(array) { RubiCL.opencl_device = RubiCL::CPU; RubiCL::Config::Features.use_host_mem = true; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
                       }.merge(ruby_input),

                       'RubiCL library [CPU: Intel i7 dual-core (MBA)] without use host ptr' => {
                         function: ->(array) { RubiCL.opencl_device = RubiCL::CPU; RubiCL::Config::Features.use_host_mem = false; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
                       }.merge(ruby_input),

                       'RubiCL library [GPU: Intel HD5000 (MBA)] with use host ptr' => {
                         function: ->(array) { RubiCL.opencl_device = RubiCL::GPU; RubiCL::Config::Features.use_host_mem = true; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
                       }.merge(ruby_input),

                       'RubiCL library [GPU: Intel HD5000 (MBA)] without use host ptr' => {
                         function: ->(array) { RubiCL.opencl_device = RubiCL::GPU; RubiCL::Config::Features.use_host_mem = false; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
                       }.merge(ruby_input),
                       'Ruby doing the task' => {
                         function: ->(array) { array.map { |x| x * x }.select { |x| x % 2 == 0 } },
                       }.merge(ruby_input),
)
