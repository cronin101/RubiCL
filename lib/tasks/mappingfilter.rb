module Hadope
  class MappingFilter < Filter
    attr_reader :before_filter, :filter

    def initialize(pre_map: nil, filter: nil, post_map: nil)
      input_variable = !(pre_map.nil?) ? pre_map.input_variable : filter.input_variable
      super(filter.type, input_variable, filter.statements.first)

      @before = !(pre_map.nil?) ? pre_map.statements : []
      @filter = filter.statements
      @after  = !(post_map.nil?) ? post_map.statements : []

      unless pre_map.nil?
        add_variables pre_map.input_variable
        unless filter.input_variable == pre_map.output_variable
          add_variables pre_map.output_variable
          @before.push "#{filter.input_variable} = #{pre_map.output_variable}"
        end
      end

      unless post_map.nil?
        add_variables post_map.output_variable
        unless post_map.input_variable == filter.input_variable
          add_variables post_map.input_variable
          @after.unshift "#{post_map.input_variable} = #{filter.input_variable}"
        end
      end

      @input_variable  = (pre_map || filter).input_variable
      @output_variable = (post_map || pre_map).output_variable
    end

    def statements
      (@before + @filter.map { |f| "?{#{f}}?"} + @after).flatten
    end

    def has_post_map?
      !(@after.empty?)
    end

    def filter_fuse!(filter)
      add_variables filter.variables
      predicate = @filter.pop
      unless filter.input_variable == @output_variable
        @filter.push "#{filter.input_variable = @output_variable}"
      end
      @filter.push "(#{predicate}) && (#{filter.predicate})"
      self
    end

    def pre_fuse!(map)
      add_variables map.variables
      conversion =  if map.output_variable == @input_variable
                      []
                    else
                      pipeline_variable, @input_variable = @input_variable, map.input_variable
                      ["#{pipeline_variable} = #{map.output_variable}"]
                    end
      @before.unshift(map.statements + conversion)
      self
    end

    def post_fuse!(map)
      add_variables map.variables
      conversion =  if map.input_variable == @output_variable
                      []
                    else
                      pipeline_variable, @output_variable = @output_variable, map.output_variable
                      ["#{map.input_variable} = #{pipeline_variable}"]
                    end
      @after.push(conversion + map.statements)
      self
    end

    def body
      @before.join(";\n ") << ";\n" << @filter[0..-2].join(";\n") << ";\n" <<
          "int flag = #{@filter.last} ? 1 : 0;\n" << "if (flag) { \n" <<
          @after.join(";\n ") << ";\n" <<
          "}"
    end

    def return_statements
<<CL
    presence_array[global_id] = flag;
    data_array[global_id] = #@output_variable;
CL
    end

  end
end
