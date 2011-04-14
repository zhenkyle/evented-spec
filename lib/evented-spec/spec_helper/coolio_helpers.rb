module EventedSpec
  module SpecHelper
    module CoolioHelpers
      module GroupHelpers
        # Adds before hook that will run inside coolio event loop before example starts.
        #
        # @param [Symbol] scope for hook (only :each is supported currently)
        # @yield hook block
        def coolio_before(scope = :each, &block)
          raise ArgumentError, "coolio_before only supports :each scope" unless :each == scope
          evented_spec_hooks_for(:coolio_before) << block
        end

        # Adds after hook that will run inside coolio event loop after example finishes.
        #
        # @param [Symbol] scope for hook (only :each is supported currently)
        # @yield hook block
        def coolio_after(scope = :each, &block)
          raise ArgumentError, "coolio_after only supports :each scope" unless :each == scope
          evented_spec_hooks_for(:coolio_after).unshift block
        end
      end # module GroupHelpers

      module ExampleHelpers
        # Yields to block inside cool.io loop, :spec_timeout option (in seconds) is used to
        # force spec to timeout if something goes wrong and EM/AMQP loop hangs for some
        # reason.
        #
        # @param [Hash] options for cool.io
        # @param opts [Numeric] :spec_timeout (nil) Amount of time before spec is stopped by timeout
        # @yield block to execute after cool.io loop starts
        def coolio(opts = {}, &block)
          opts = default_options.merge opts
          @evented_example = CoolioExample.new(opts, self, &block)
          @evented_example.run
        end
      end # module ExampleHelpers
    end # module CoolioHelpers
  end # module SpecHelper
end # module EventedSpec

module EventedSpec
  module SpecHelper
    module GroupMethods
      include EventedSpec::SpecHelper::CoolioHelpers::GroupHelpers
    end # module GroupHelpers
    include EventedSpec::SpecHelper::CoolioHelpers::ExampleHelpers
  end # module SpecHelper
end # module EventedSpec
