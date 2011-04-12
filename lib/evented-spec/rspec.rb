require 'evented-spec/amqp'
require 'evented-spec/evented_example'
require 'evented-spec/util'

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
  # respectively. Each example is running in a separate event loop,you can control
  # for timeouts either with :spec_timeout option given to #amqp/#em method or setting
  # a default timeout using default_timeout(timeout) macro inside describe/context block.
  #
  # noinspection RubyArgCount
  module SpecHelper

    SpecTimeoutExceededError = Class.new(RuntimeError)

    # Class methods (macros) for any example groups that includes SpecHelper.
    # You can use these methods as macros inside describe/context block.
    #
    module GroupMethods
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
      def default_timeout(spec_timeout = nil)
        if spec_timeout
          default_options[:spec_timeout] = spec_timeout
        else
          default_options[:spec_timeout] || self.superclass.default_timeout || 2.71
        end
      end

      # Sets/retrieves default AMQP.start options for this example group
      # and its nested groups.
      #
      def default_options(opts = nil)
        evented_spec_metadata[:default_options] ||= {}
        if opts
          evented_spec_metadata[:default_options].merge!(opts)
        else
          evented_spec_metadata[:default_options]
        end
      end

      # Add before hook that will run inside EM event loop
      def em_before(scope = :each, &block)
        raise ArgumentError, "em_before only supports :each scope" unless :each == scope
        em_hooks[:em_before] << block
      end

      # Add after hook that will run inside EM event loop
      def em_after(scope = :each, &block)
        raise ArgumentError, "em_after only supports :each scope" unless :each == scope
        em_hooks[:em_after].unshift block
      end

      # Add before hook that will run inside AMQP connection (AMQP.start loop)
      def amqp_before(scope = :each, &block)
        raise ArgumentError, "amqp_before only supports :each scope" unless :each == scope
        em_hooks[:amqp_before] << block
      end

      # Add after hook that will run inside AMQP connection (AMQP.start loop)
      def amqp_after(scope = :each, &block)
        raise ArgumentError, "amqp_after only supports :each scope" unless :each == scope
        em_hooks[:amqp_after].unshift block
      end

      # Collection of evented hooks for THIS example group
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
    def default_options
      @em_default_options ||= self.class.default_options.dup rescue {}
    end

    # Yields to a given block inside EM.run and AMQP.start loops. This method takes
    # any option that is accepted by EventMachine::connect. Options for AMQP.start include:
    # * :user => String (default ‘guest’) - Username as defined by the AMQP server.
    # * :pass => String (default ‘guest’) - Password as defined by the AMQP server.
    # * :vhost => String (default ’/’)    - Virtual host as defined by the AMQP server.
    # * :timeout => Numeric (default nil) - *Connection* timeout, measured in seconds.
    # * :logging => Bool (default false) - Toggle the extremely verbose AMQP logging.
    #
    # In addition to EM and AMQP options, :spec_timeout option (in seconds) is used
    # to force spec to timeout if something goes wrong and EM/AMQP loop hangs for some
    # reason. SpecTimeoutExceededError is raised if it happens.
    #
    def amqp(opts = {}, &block)
      opts = default_options.merge opts
      @evented_example = AMQPExample.new(opts, self, &block)
      @evented_example.run
    end

    # Yields to block inside EM loop, :spec_timeout option (in seconds) is used to
    # force spec to timeout if something goes wrong and EM/AMQP loop hangs for some
    # reason. SpecTimeoutExceededError is raised if it happens.
    #
    # For compatibility with EM-Spec API, em method accepts either options Hash
    # or numeric timeout in seconds.
    #
    def em(opts = {}, &block)
      opts = default_options.merge(opts.is_a?(Hash) ? opts : { :spec_timeout =>  opts })
      @evented_example = EMExample.new(opts, self, &block)
      @evented_example.run
    end

    # Yields to block inside cool.io loop, :spec_timeout option (in seconds) is used to
    # force spec to timeout if something goes wrong and EM/AMQP loop hangs for some
    # reason. SpecTimeoutExceededError is raised if it happens.
    def coolio(opts = {}, &block)
      opts = default_options.merge opts
      @evented_example = CoolioExample.new(opts, self, &block)
      @evented_example.run
    end

    # Breaks the event loop and finishes the spec. This should be called after
    # you are reasonably sure that your expectations either succeeded or failed.
    # Done yields to any given block first, then stops EM event loop.
    # For amqp specs, stops AMQP and cleans up AMQP state.
    #
    # You may pass delay (in seconds) to done. If you do so, please keep in mind
    # that your (default or explicit) spec timeout may fire before your delayed done
    # callback is due, leading to SpecTimeoutExceededError
    #
    def done(*args, &block)
      @evented_example.done *args, &block if @evented_example
    end

    # Manually sets timeout for currently running example
    #
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
  end

  # Including EventedSpec::EMSpec module into your example group, each example of this group
  # will run inside EM.run loop without the need to explicitly call 'em'.
  #
  module EMSpec
    def self.included(example_group)
      example_group.send(:include, SpecHelper)
      example_group.extend ClassMethods
    end

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
  end
end
