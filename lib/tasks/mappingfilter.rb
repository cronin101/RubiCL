module Hadope
  class MappingFilter < Filter
    attr_reader :before_filter, :filter

    def initialize(pre_map: nil, filter: nil, post_map: nil)
      input_variable = !(pre_map.nil?) ? pre_map.input_variable : filter.input_variable
      super(filter.type, input_variable, filter.statements.first)

      @before = !(pre_map.nil?) ? pre_map.statements : []
      @filter = filter.statements
      @after  = !(post_map.nil?) ? post_map.statements : []

      if !(pre_map.nil?)
        add_variables pre_map.input_variable
        unless filter.input_variable == pre_map.output_variable
          add_variables pre_map.output_variable
          @before.push "#{filter.input_variable} = #{pre_map.output_variable}"
        end
      end

      if !(post_map.nil?)
        add_variables post_map.output_variable
        unless post_map.input_variable == filter.input_variable
          add_variables post_map.input_variable
          @after.unshift "#{post_map.input_variable} = #{filter.input_variable}"
        end
      end

      @map_input_variable  = (pre_map || post_map).input_variable
      @map_output_variable = (post_map || pre_map).output_variable
    end

    def statements
      (@before + @filter + @after).flatten
    end

    def pre_fuse!(map)
      add_variables map.variables
      conversion =  if map.output_variable == @map_input_variable
                      []
                    else
                      pipeline_variable, @map_input_variable = @map_input_variable, map.input_variable
                      ["#{pipeline_variable} = #{map.output_variable}"]
                    end
      @before.unshift(map.statements + conversion)
      self
    end

    def post_fuse!(map)
      add_variables map.variables
      conversion =  if map.input_variable == @map_output_variable
                      []
                    else
                      pipeline_variable, @map_output_variable = @map_output_variable, map.output_variable
                      ["#{map.input_variable} = #{pipeline_variable}"]
                    end
      @after.push(conversion + map.statements)
      self
    end

    def body
      @before.join(";\n ") << ";\nint flag = #{@filter.first} ? 1 : 0;" << @after.join(";\n ") << ';'
    end

    def return_statements
<<CL
    presence_array[global_id] = flag;
    data_array[global_id] = #@map_output_variable;
CL
    end

  end
end
