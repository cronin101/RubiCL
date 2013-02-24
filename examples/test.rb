#!/usr/bin/env ruby

require_relative '../hadope.rb'
FP = HaDope::Functional

# Creating a DataSet
HaDope::DataSet.create  name: :one_to_ten,
                        type: :int,
                        data: (1..10).to_a

# Creating a Map function
function =<<C_CODE
i += 1;
C_CODE

FP::Map.create  name: :add_one,
                key: [:int, :i],
                function: function

# Creating a more complicated Map function
function =<<C_CODE
int j;
for( j = i-1; j > 0; j--){
  i = i*j;
}
C_CODE

FP::Map.create  name: :compute_factorial,
                key: [:int, :i],
                function: function

# Creating a Filter function
function =<<C_CODE
i = i + 3;
C_CODE

FP::Filter.create name: :add_three_is_even,
                  key: [:int, :i],
                  function: function,
                  test: 'i % 2 == 0'

# Chaining actions on CPU
results = HaDope::CPU.get.load(:one_to_ten).fp_map(:add_one, :compute_factorial, :add_one).output
puts ":one_to_ten :add_one :compute_factoral :add_one is: #{results}"

# Kernel generation
puts "Kernel for :add_one is: \n#{FP::Map[:add_one].kernel}"
puts "Kernel for :add_three_is_even is: \n#{FP::Filter[:add_three_is_even].kernel}"

# Filtering datasets
filtered = HaDope::CPU.get.load(:one_to_ten).fp_filter(:add_three_is_even)
puts "Dataset :one_to_ten is:                   #{filtered.output}"
puts "Presence Array for :add_three_is_even is: #{filtered.presence_array}"
