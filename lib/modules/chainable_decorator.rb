module RubiCL::ChainableDecorator
  # This decorator makes a function return self on exit, so that chainable calls will
  # all get sent to the same object, allowing the ( map -> filter -> map ) work-flow.

  module ClassMethods
    # Experimental method-decorator. Handle with care!
    def chainable(method)
      method_body = instance_method(method)
      define_method method do |*arg, &block|
        method_body.bind(self).call(*arg, &block)
        self
      end

      method
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
