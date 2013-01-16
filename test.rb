require './hadope.rb'

HaDope::DataSet.create({
  name: :one_to_onehundred,
  type: :int,
  data: (1..100).to_a
})

# Creating a Map function
HaDope::Map.create({
  name: :add_one,
  key: [:int, :i],
  function:
<<kernel
  i += 1;
kernel
})

# Creating a Filter function
HaDope::Filter.create({
  name: :doubled_is_even?,
  key: [:int, :i],
  test: 'i % 2 == 0',
  function:
<<kernel
  i = i * 2;
kernel
})

#Showing names of DataSets
all_data_sets = HaDope::DataSet.names
puts all_data_sets.inspect

#Showing names of Maps
all_map_names = HaDope::Map.names
puts all_map_names.inspect

#Showing names of Filters
all_filter_names = HaDope::Filter.names
puts all_filter_names.inspect

#Retrieving a single DataSet by name
a_data_set = HaDope::DataSet[:one_to_onehundred]
puts a_data_set.inspect

#Retrieving a single Map function by name
a_map = HaDope::Map[:add_one]
puts a_map.inspect

#Retrieving a single Filter function by name
a_filter = HaDope::Filter[:doubled_is_even?]
puts a_filter.inspect

#Idea of how to execute a series of actions
results = HaDope::GPU.new.load(:one_to_onehundred).map(:add_one).filter(:doubled_is_even?).output
puts results.inspect
