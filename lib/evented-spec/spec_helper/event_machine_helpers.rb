module EventedSpec
  module SpecHelper
    module EventMachineHelpers
      module GroupMethods
        # Adds before hook that will run inside EM event loop before example starts.
        #
        # @param [Symbol] scope for hook (only :each is supported currently)
        # @yield hook block
        def em_before(scope = :each, &block)
          raise ArgumentError, "em_before only supports :each scope" unless :each == scope
          evented_spec_hooks_for(:em_before) << block
        end

        # Adds after hook that will run inside EM event loop after example finishes.
        #
        # @param [Symbol] scope for hook (only :each is supported currently)
        # @yield hook block
        def em_after(scope = :each, &block)
          raise ArgumentError, "em_after only supports :each scope" unless :each == scope
          evented_spec_hooks_for(:em_after).unshift block
        end
      end # module GroupMethods

      module ExampleMethods
        # Yields to block inside EM loop, :spec_timeout option (in seconds) is used to
        # force spec to timeout if something goes wrong and EM/AMQP loop hangs for some
        # reason.
        #
        # For compatibility with EM-Spec API, em method accepts either options Hash
        # or numeric timeout in seconds.
        #
        # @param [Hash] options for eventmachine
        # @param opts [Numeric] :spec_timeout (nil) Amount of time before spec is stopped by timeout
        # @yield block to execute after eventmachine loop starts
        def em(opts = {}, &block)
          opts = default_options.merge(opts.is_a?(Hash) ? opts : { :spec_timeout =>  opts })
          @evented_example = EMExample.new(opts, self, &block)
          @evented_example.run
        end
      end # module ExampleMethods
    end # module EventMachine
  end # module SpecHelper
end # module EventedSpec

module EventedSpec
  module SpecHelper
    module GroupMethods
      include EventedSpec::SpecHelper::EventMachineHelpers::GroupMethods
    end # module GroupMethods
    include EventedSpec::SpecHelper::EventMachineHelpers::ExampleMethods
  end # module SpecHelper
end # module EventedSpec