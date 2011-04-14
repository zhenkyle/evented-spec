module EventedSpec
  module SpecHelper
    module AMQPHelpers # naming is v
      module GroupMethods
        # Adds before hook that will run inside AMQP connection (AMQP.start loop)
        # before example starts
        #
        # @param [Symbol] scope for hook (only :each is supported currently)
        # @yield hook block
        def amqp_before(scope = :each, &block)
          raise ArgumentError, "amqp_before only supports :each scope" unless :each == scope
          evented_spec_hooks_for(:amqp_before) << block
        end

        # Adds after hook that will run inside AMQP connection (AMQP.start loop)
        # after example finishes
        #
        # @param [Symbol] scope for hook (only :each is supported currently)
        # @yield hook block
        def amqp_after(scope = :each, &block)
          raise ArgumentError, "amqp_after only supports :each scope" unless :each == scope
          evented_spec_hooks_for(:amqp_after).unshift block
        end
      end # module GroupMethods

      module ExampleMethods
        # Yields to a given block inside EM.run and AMQP.start loops.
        #
        # @param [Hash] options for amqp connection initialization
        # @option opts [String] :user ('guest') Username as defined by the AMQP server.
        # @option opts [String] :pass ('guest') Password as defined by the AMQP server.
        # @option opts [String] :vhost ('/') Virtual host as defined by the AMQP server.
        # @option opts [Numeric] :timeout (nil) *Connection* timeout, measured in seconds.
        # @option opts [Boolean] :logging (false) Toggle the extremely verbose AMQP logging.
        # @option opts [Numeric] :spec_timeout (nil) Amount of time before spec is stopped by timeout
        # @yield block to execute after amqp connects
        def amqp(opts = {}, &block)
          opts = default_options.merge opts
          @evented_example = AMQPExample.new(opts, self, &block)
          @evented_example.run
        end
      end # module ExampleMethods
    end # module AMQP
  end # module SpecHelper
end # module EventedSpec

module EventedSpec
  module SpecHelper
    module GroupMethods
      include EventedSpec::SpecHelper::AMQPHelpers::GroupMethods
    end # module GroupMethods

    include EventedSpec::SpecHelper::AMQPHelpers::ExampleMethods
  end # module SpecHelper
end # module EventedSpec