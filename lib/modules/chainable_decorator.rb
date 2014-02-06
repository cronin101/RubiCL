module Hadope::ChainableDecorator

  module ClassMethods
    # Experimental method-decorator. Handle with care!
    def chainable method
      method_body = instance_method(method)
      define_method method do |*arg, &block|
        method_body.bind(self).(*arg, &block)
        self
      end

      method
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

end
