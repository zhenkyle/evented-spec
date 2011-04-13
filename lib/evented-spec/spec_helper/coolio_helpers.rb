module EventedSpec
  module SpecHelper
    module CoolioHelpers
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
    include EventedSpec::SpecHelper::CoolioHelpers::ExampleHelpers
  end # module SpecHelper
end # module EventedSpec
