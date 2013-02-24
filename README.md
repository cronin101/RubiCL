# HaDope: An OpenCL Accelerator for Data-Parallel Calcluations

# Cheatsheet

#### Creating a DataSet
```ruby
HaDope::DataSet.create(
  name: :one_to_ten,
  type: :int,
  data: (1..10).to_a
)
```

#### Creating Map and Filter functions
```ruby
FP::Map.create(
  name: :add_one,
  key: [:int, :i],
  function: 'i += 1;'
)

FP::Filter.create(
  name: :add_three_is_even,
  key: [:int, :i],
  function: 'i += 3;',
  test: 'i % 2 == 0'
)
```
