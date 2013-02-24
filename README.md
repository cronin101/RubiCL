# HaDope*: An OpenCL Accelerator for Parallel Calcluations.
###### *Feel free to groan, blame [@wenkakes](http://github.com/wenkakes) for the name.
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
@cpu_device = HaDope::CPU.get
@gpu_device = HaDope::GPU.get

@cpu_device.load(:one_to_ten)
@cpu_device.fp_map(:add_one)
@cpu_device.output
#=> [2,3,4,5,6,7,8,9,10,11]

# Tasks are chainable...
@gpu_device.load(:one_to_ten).fp_map(:add_one).output
#=> [2,3,4,5,6,7,8,9,10,11]

# Map tasks are too...
@gpu_device.load(:one_to_ten).fp_map(:add_one, :add_one, :add_one).output
#=> [4,5,6,7,8,9,10,11,12,13]
```

#### Cleaning up when you are done
```ruby
# Release any allocated memory held by the OpenCL environment or completed tasks.
@cpu_device.clean
@gpu_device.clean
```
