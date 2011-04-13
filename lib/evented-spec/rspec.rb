# You can include one of the following modules into your example groups:
# EventedSpec::SpecHelper,
# EventedSpec::AMQPSpec,
# EventedSpec::EMSpec.
#
# EventedSpec::SpecHelper module defines #ampq and #em methods that can be safely used inside
# your specs (examples) to test code running inside AMQP.start or EM.run loop
# respectively. Each example is running in a separate event loop,you can control
# for timeouts either with :spec_timeout option given to #amqp/#em method or setting
# a default timeout using default_timeout(timeout) macro inside describe/context block.
#
# If you include EventedSpec::Spec module into your example group, each example of this group
# will run inside AMQP.start loop without the need to explicitly call 'amqp'. In order to
# provide options to AMQP loop, default_options({opts}) macro is defined.
#
# Including EventedSpec::EMSpec module into your example group, each example of this group will
# run inside EM.run loop without the need to explicitly call 'em'.
#
# In order to stop AMQP/EM loop, you should call 'done' AFTER you are sure that your
# example is finished and your expectations executed. For example if you are using
# subscribe block that tests expectations on messages, 'done' should be probably called
# at the end of this block.
#
module EventedSpec

  # EventedSpec::SpecHelper module defines #ampq and #em methods that can be safely used inside
  # your specs (examples) to test code running inside AMQP.start or EM.run loop
  # respectively. Each example is running in a separate event loop, you can control
  # for timeouts either with :spec_timeout option given to #amqp/#em/#coolio method or setting
  # a default timeout using default_timeout(timeout) macro inside describe/context block.
  module SpecHelper
    # Error which shows in RSpec log when example does not call #done inside
    # of event loop.
    SpecTimeoutExceededError = Class.new(RuntimeError)

    # Class methods (macros) for any example groups that includes SpecHelper.
    # You can use these methods as macros inside describe/context block.
    module GroupMethods
      # Returns evented-spec related metadata for particular example group.
      # Metadata is cloned from parent to children, so that children inherit
      # all the options and hooks set in parent example groups
      #
      # @return [Hash] hash with example group metadata
      def evented_spec_metadata
        if @evented_spec_metadata
          @evented_spec_metadata
        else
          @evented_spec_metadata = superclass.evented_spec_metadata rescue {}
          @evented_spec_metadata = EventedSpec::Util.deep_clone(@evented_spec_metadata)
        end
      end # evented_spec_metadata

      # Sets/retrieves default timeout for running evented specs for this
      # example group and its nested groups.
      #
      # @param [Float] desired timeout for the example group
      # @return [Float]
      def default_timeout(spec_timeout = nil)
        if spec_timeout
          default_options[:spec_timeout] = spec_timeout
        else
          default_options[:spec_timeout] || self.superclass.default_timeout
        end
      end

      # Sets/retrieves default AMQP.start options for this example group
      # and its nested groups.
      #
      # @param [Hash] context-specific options for helper methods like #amqp, #em, #coolio
      # @return [Hash]
      def default_options(opts = nil)
        evented_spec_metadata[:default_options] ||= {}
        if opts
          evented_spec_metadata[:default_options].merge!(opts)
        else
          evented_spec_metadata[:default_options]
        end
      end

      # Adds before hook that will run inside EM event loop before example starts.
      #
      # @param [Symbol] scope for hook (only :each is supported currently)
      # @yield hook block
      def em_before(scope = :each, &block)
        raise ArgumentError, "em_before only supports :each scope" unless :each == scope
        em_hooks[:em_before] << block
      end

      # Adds after hook that will run inside EM event loop after example finishes.
      #
      # @param [Symbol] scope for hook (only :each is supported currently)
      # @yield hook block
      def em_after(scope = :each, &block)
        raise ArgumentError, "em_after only supports :each scope" unless :each == scope
        em_hooks[:em_after].unshift block
      end

      # Adds before hook that will run inside AMQP connection (AMQP.start loop)
      # before example starts
      #
      # @param [Symbol] scope for hook (only :each is supported currently)
      # @yield hook block
      def amqp_before(scope = :each, &block)
        raise ArgumentError, "amqp_before only supports :each scope" unless :each == scope
        em_hooks[:amqp_before] << block
      end

      # Adds after hook that will run inside AMQP connection (AMQP.start loop)
      # after example finishes
      #
      # @param [Symbol] scope for hook (only :each is supported currently)
      # @yield hook block
      def amqp_after(scope = :each, &block)
        raise ArgumentError, "amqp_after only supports :each scope" unless :each == scope
        em_hooks[:amqp_after].unshift block
      end

      # Collection of evented hooks for current example group
      #
      # @return [Hash] hash with hooks
      def em_hooks
        evented_spec_metadata[:em_hooks] ||= {
          :em_before   => [],
          :em_after    => [],
          :amqp_before => [],
          :amqp_after  => []
        }
      end
    end

    def self.included(example_group)
      unless example_group.respond_to? :default_timeout
        example_group.extend GroupMethods
      end
    end

    # Retrieves default options passed in from enclosing example groups
    #
    # @return [Hash] default option for currently running example
    def default_options
      @em_default_options ||= self.class.default_options.dup rescue {}
    end

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

    # Breaks the event loop and finishes the spec. This should be called after
    # you are reasonably sure that your expectations succeeded.
    # Done yields to any given block first, then stops EM event loop.
    # For amqp specs, stops AMQP and cleans up AMQP state.
    #
    # You may pass delay (in seconds) to done. If you do so, please keep in mind
    # that your (default or explicit) spec timeout may fire before your delayed done
    # callback is due, leading to SpecTimeoutExceededError
    #
    # @param [Float] Delay before event loop is stopped
    def done(*args, &block)
      @evented_example.done *args, &block if @evented_example
    end

    # Manually sets timeout for currently running example. If spec doesn't call
    # #done before timeout, it is marked as failed on timeout.
    #
    # @param [Float] Delay before event loop is stopped with error
    def timeout(*args)
      @evented_example.timeout *args if @evented_example
    end

  end # module SpecHelper

  # If you include EventedSpec::AMQPSpec module into your example group, each example of this group
  # will run inside AMQP.start loop without the need to explicitly call 'amqp'. In order
  # to provide options to AMQP loop, default_options class method is defined. Remember,
  # when using EventedSpec::Specs, you'll have a single set of AMQP.start options for all your
  # examples.
  #
  module AMQPSpec
    def self.included(example_group)
      example_group.send(:include, SpecHelper)
      example_group.extend(ClassMethods)
    end

    # @private
    module ClassMethods
      def it(*args, &block)
        if block
          new_block = Proc.new {|example_group_instance| (example_group_instance || self).instance_eval { amqp(&block) } }
          super(*args, &new_block)
        else
          # pending example
          super
        end
      end # it
    end # ClassMethods
  end # AMQPSpec

  # Including EventedSpec::EMSpec module into your example group, each example of this group
  # will run inside EM.run loop without the need to explicitly call 'em'.
  #
  module EMSpec
    def self.included(example_group)
      example_group.send(:include, SpecHelper)
      example_group.extend ClassMethods
    end

    # @private
    module ClassMethods
      def it(*args, &block)
        if block
          # Shared example groups seem to pass example group instance
          # to the actual example block
          new_block = Proc.new {|example_group_instance| (example_group_instance || self).instance_eval { em(&block) } }
          super(*args, &new_block)
        else
          # pending example
          super
        end
      end # it
    end # ClassMethods
  end # EMSpec
end # EventedSpec
