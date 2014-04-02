module RubiCL
  module DeviceService

    class BufferManager

      include RubiCLBufferBackend
      include RequireType

      Cache = Struct.new(:dataset)

      def initialize(env)
        @environment = env
        @cache = Cache.new(nil)
      end

      def load(type: nil, object: nil)
        raise "No object passed to #load" unless object

        @buffer = case type
        when :int then loaded_integer_object object
        when :double  then loaded_double_object object
        else
          raise "Unknown type: #{type}"
        end
      end

      requires_type :int, (sets_type :int_tuple, def zip_load(fst: @buffer, snd: nil)
        raise "Snd missing" unless snd
        case snd
        when File
          snd_buffer = create_buffer_from_dataset :pinned_intfile_buffer, snd.path
        else
          raise "Datasets must be the same length" unless buffer_length(fst) == snd.size
          snd_buffer = create_buffer_from_dataset :pinned_integer_buffer, snd.to_a
        end
          @double_buffer = [fst, snd_buffer]
        invalidate_cache
      end)

      def size
        case loaded_type
        when :int_tuple
          buffer_length(@double_buffer.first)
        else
          buffer_length(@buffer)
        end
      end

      requires_type :int_tuple, (sets_type :int, def zipped_choose(which)
        case which
        when :fst
          @buffer = @double_buffer.first
        when :snd
          @buffer = @double_buffer.last
        else
          raise "Must choose fst or snd"
        end
      end)

      def retrieve(type:nil)
        return @cache.dataset if @cache.dataset
        case type
        when :int then retrieve_integers
        when :double then retrieve_doubles
        else
          raise "Unknown type: #{type}"
        end
      end

      def zip_retrieve
        return *@double_buffer
      end

      def access(type: nil)
        raise "Must provided expected type when accessing buffer" unless type

        check_buffer_type! type
        @buffer
      end

      def invalidate_cache
        @cache.dataset = nil
      end

      def type=(val)
        @buffer_type = val
      end

      def type
        @buffer_type
      end

      def unary_type?
        unary_types.include? loaded_type
      end

      private

      # FIXME: Make this sane
      def is_hybrid?
        false
      end

      sets_type :double, def loaded_double_object object
        case object
        when Array
          create_buffer_from_dataset :pinned_double_buffer, object
        end
      end

      sets_type :int, def loaded_integer_object object
        case object
        when Array, Range
          array = Array(object)
          result = if RubiCL::Config::Features.use_host_mem
            create_buffer_from_dataset :pinned_integer_buffer, array
          else
            create_memory_buffer(array.length, 'int').tap do |buffer|
              transfer_integer_dataset_to_buffer array, buffer
            end
          end
          technique = RubiCL::Config::Features.use_host_mem ? 'Pinned' : 'Loaded'
          Logger.timing_info "#{technique} #{("Integer " << object.class.to_s).yellow} in #{last_memory_duration.round(3).to_s.green} ms"
          result

        when File
          path = object.path
          buffer = create_buffer_from_dataset :pinned_intfile_buffer, path
          invalidate_cache
          buffer

        else
          raise "No idea how to pin #{object.inspect}"
        end
      end

      requires_type :int, def retrieve_integers
        result = if RubiCL::Config::Features.use_host_mem
          retrieve_from_device :pinned_integer_dataset
        else
          retrieve_from_device :integer_dataset
        end
        Logger.timing_info "Waiting for in-progress tasks ".yellow << "took #{last_computation_duration.round(3).to_s.green} ms"
        Logger.timing_info "Retrieved " + "#{buffer_length(@buffer)} Integers".yellow + " in #{last_memory_duration.round(3).to_s.green} ms"
        result
      end

      requires_type :double, def retrieve_doubles
        result = retrieve_from_device :pinned_double_dataset
      end

      def create_buffer_from_dataset(buffer_type, dataset)
        send("create_#{buffer_type}", @cache.dataset = dataset)
      end

      def retrieve_from_device dataset_type
        @cache.dataset = send("retrieve_#{dataset_type}_from_buffer", @buffer)
      end

    end

  end
end
