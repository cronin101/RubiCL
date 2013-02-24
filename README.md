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
FP = HaDope::Functional

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

#### Dispatching tasks to OpenCL Compute Devices
```ruby
@device = HaDope::CPU.get

@device.load(:one_to_ten)
@device.fp_map(:add_one)
@device.output
#=> [2,3,4,5,6,7,8,9,10,11]

# Tasks are chainable...
@device.load(:one_to_ten).fp_map(:add_one).output
#=> [2,3,4,5,6,7,8,9,10,11]

# Map tasks are too...
@device.load(:one_to_ten).fp_map(:add_one, :add_one, :add_one).output
#=> [4,5,6,7,8,9,10,11,12,13]
```
