require 'asymptotic'
require './hadope'

<<<<<<< Updated upstream
seeds = (8..20)
=======
seeds = (15..25)
>>>>>>> Stashed changes

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

=begin
  "RubiCL library [Task Split Across CPU and GPU]" => {
    function: ->(array){ Hadope.opencl_device = Hadope::HybridDevice; array[Int].map { |x| x * x }.filter { |x| x % 2 == 0 }[Fixnum] }
  }.merge(ruby_input),
=end

  "Ruby doing the task" => {
<<<<<<< Updated upstream
    function: ->(array){ array.map { |x| x + x }.select { |x| x % 2 == 0 } },
=======
    function: ->(array){ array.map { |x| x * 1 }.select { |x| x % 2 == 0 } },
>>>>>>> Stashed changes
  }.merge(ruby_input),
)

