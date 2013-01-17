#!/usr/bin/env ruby

require_relative '../hadope.rb'

# Creating a DataSet
HaDope::DataSet.create({
  name: :one_to_onehundred,
  type: :int,
  data: (1..100).to_a
})

# Creating a Map function
function =<<C_CODE
i += 1;
return i;
C_CODE

HaDope::Map.create({
  name: :add_one,
  key: [:int, :i],
  function: function
})

# Creating a more complicated Map function
function =<<C_CODE
for( j = i-1; i > 0; j--){
  i = i*j;
}
return i;
C_CODE

HaDope::Map.create({
  name: :compute_factorial,
  key: [:int, :i],
  other_vars: [[:int, :j]],
  function: function
})

# Creating a Filter function
function =<<C_CODE
i = i * 2;
C_CODE

HaDope::Filter.create({
  name: :doubled_is_even?,
  key: [:int, :i],
  test: 'i % 2 == 0',
  function: function
})

#Idea of how to execute a series of actions
results = HaDope::GPU.get.load(:one_to_onehundred).map(:add_one).map(:compute_factorial).filter(:doubled_is_even?).output
