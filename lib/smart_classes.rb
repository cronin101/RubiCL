class HaDope
  module SmartClasses
    def self.included(base)
      base.extend(ClassMethods)
      base.class_variable_set(:@@instances, {})
    end

    module ClassMethods
      def create(*splat)
        self.new(*splat).save
      end

      def all
        self.class_variable_get(:@@instances).values
      end

      def [](name)
        self.class_variable_get(:@@instances)[name]
      rescue NameError
        nil
      end

      def names
        self.class_variable_get(:@@instances).keys
      end
    end

  end
end
