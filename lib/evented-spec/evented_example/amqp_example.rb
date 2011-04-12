module EventedSpec
  module SpecHelper
    # Represents spec running inside AMQP.start loop
    class AMQPExample < EMExample
      # Run @block inside the AMQP.start loop
      def run
        run_em_loop do
          AMQP.start_connection(@opts) do
            run_em_hooks :amqp_before
            @example_group_instance.instance_eval(&@block)
          end
        end
      end

      # Breaks the event loop and finishes the spec. It yields to any given block first,
      # then stops AMQP, EM event loop and cleans up AMQP state.
      #
      def done(delay = nil)
        delayed(delay) do
          yield if block_given?
          EM.next_tick do
            run_em_hooks :amqp_after
            if AMQP.connection && !AMQP.closing?
              AMQP.stop_connection do
                # Cannot call finish_em_loop before connection is marked as closed
                # This callback is called before that happens.
                EM.next_tick { finish_em_loop }
              end
            else
              # Need this branch because if AMQP couldn't connect,
              # the callback would never trigger
              AMQP.cleanup_state
              EM.next_tick { finish_em_loop }
            end
          end
        end
      end

      # Called from run_event_loop when event loop is finished, before any exceptions
      # is raised or example returns. We ensure AMQP state cleanup here.
      def finish_example
        AMQP.cleanup_state
        super
      end
    end # class AMQPExample < EventedExample
  end # module SpecHelper
end # module EventedExample