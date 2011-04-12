module EventedSpec
  module SpecHelper
    # Represents example running inside some type of event loop.
    # You are not going to use or interact with this class and its descendants directly.
    #
    # @abstract
    class EventedExample
      # Default options to use with the examples
      DEFAULT_OPTIONS = {
        :spec_timeout => 1
      }

      # Create new evented example
      def initialize(opts, example_group_instance, &block)
        @opts, @example_group_instance, @block = DEFAULT_OPTIONS.merge(opts), example_group_instance, block
      end

      # Called from #run_event_loop when event loop is stopped,
      # but before the example returns.
      # Descendant classes may redefine to clean up type-specific state.
      #
      # @abstract
      def finish_example
        raise @spec_exception if @spec_exception
      end

      # Run the example.
      #
      # @abstract
      def run
        raise NotImplementedError, "you should implement #run in #{self.class.name}"
      end

      # Sets timeout for currently running example
      #
      # @abstract
      def timeout(spec_timeout)
        raise NotImplementedError, "you should implement #timeout in #{self.class.name}"
      end

      # Breaks the event loop and finishes the spec.
      #
      # @abstract
      def done(delay=nil, &block)
        raise NotImplementedError, "you should implement #done method in #{self.class.name}"
      end

      # Override this method in your descendants
      #
      # @note delay may be nil, implying you need to execute the block immediately.
      # @abstract
      def delayed(delay = nil, &block)
        raise NotImplementedError, "you should implement #delayed method in #{self.class.name}"
      end # delayed(delay, &block)
    end # class EventedExample
  end # module SpecHelper
end # module AMQP

require 'evented-spec/evented_example/em_example'
require 'evented-spec/evented_example/amqp_example'
require 'evented-spec/evented_example/coolio_example'
