#!/usr/bin/env ruby

require_relative '../hadope.rb'
FP = HaDope::Functional

# Creating a DataSet
HaDope::DataSet.create({
  name: :one_to_onehundred,
  type: :int,
  data: (1..10).to_a
})

# Creating a Map function
function =<<C_CODE
i += 1;
C_CODE

FP::Map.create({
  name: :add_one,
  key: [:int, :i],
  function: function
})

# Creating a more complicated Map function
function =<<C_CODE
int j;
for( j = i-1; j > 0; j--){
  i = i*j;
}
C_CODE

FP::Map.create({
  name: :compute_factorial,
  key: [:int, :i],
#  other_vars: [[:int, :j]],
  function: function
})

# Creating a Filter function
function =<<C_CODE
i = i * 2;
C_CODE

FP::Filter.create({
  name: :doubled_is_even,
  key: [:int, :i],
  test: 'i % 2 == 0',
  function: function
})

#Idea of how to execute a series of actions
results = HaDope::CPU.get.load(:one_to_onehundred).fp_map(:add_one, :compute_factorial, :add_one).fp_filter(:doubled_is_even).output

puts FP::Map[:add_one].kernel
puts FP::Filter[:doubled_is_even].kernel

puts results
