require 'asymptotic'
require './hadope.rb'

seeds = (1..10)

device = HaDope::CPU.get

Asymptotic::Graph::plot(125, "mapping an array",

  "Using #select" => {
    function: ->(ary){ ary.map { |x| x + 10 } },
    input_seeds: seeds,
    input_function: ->(pow){ (1..4000*pow).to_a }
  },

  "Using OpenCL" => {
    function: ->(_){ device.lambda_map_x 'x + 10'; device.output },
    input_seeds: seeds,
    input_function: ->(pow){ device.load_ints (1..4000*pow).to_a; (1..4000*pow) }

  }
)
