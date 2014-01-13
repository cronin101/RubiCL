module Hadope::RequireType

  module ClassMethods
    # Experimental method-decorators. Handle with care!
    def requires_type(type, method)
      post_check = "post_check_#{method}".to_sym
      alias_method post_check, method
      define_method method do |*arg|
        check_buffer_type! type
        send(post_check, *arg)
      end
    end

    def sets_type(type, method)
      post_set = "post_set_#{method}".to_sym
      alias_method post_set, method
      define_method method do |*arg|
        @buffer_type = type
        send(post_set, *arg)
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def check_buffer_type! type
    raise "Type Mismatch! Found #@buffer_type, expected #{type}" unless type == @buffer_type
  end

end
