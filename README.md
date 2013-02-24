# HaDope: An OpenCL Accelerator for Data-Parallel Calcluations

### Cheatsheet

#### Creating a DataSet
```ruby
HaDope::DataSet.create(
  name: :one_to_ten,
  type: :int,
  data: (1..10).to_a
)
```
