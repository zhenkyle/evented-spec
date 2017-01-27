# Monkey patching some methods into AMQP to make it more testable
module EventedSpec
  module AMQPBackports
    def self.included(base)
      base.extend ClassMethods
    end # self.included

    module ClassMethods
      def connection
        @conn
      end # connection

      def connection=(new_connection)
        @conn = new_connection
      end # connection=
    end # module ClassMethods
  end # module AMQPBackports
end # module EventedSpec

module AMQP
  # Initializes new AMQP client/connection without starting another EM loop
  def self.start_connection(opts={}, &block)
    if amqp_pre_08?
      self.connection = connect opts
      self.connection.callback(&block)
    else
      self.connection = connect opts, &block
    end
  end

  # Closes AMQP connection gracefully
  def self.stop_connection
    if AMQP.connection and not AMQP.connection.closing?
      @closing = true
      self.connection.close {
        yield if block_given?
        self.connection = nil
        cleanup_state
      }
    end
  end

  # Cleans up AMQP state after AMQP connection closes
  def self.cleanup_state
    Thread.list.each { |thread| thread[:mq] = nil }
    Thread.list.each { |thread| thread[:mq_id] = nil }
    self.connection = nil
    @closing = false
  end

  def self.amqp_pre_08?
    AMQP::VERSION < "0.8"
  end # self.amqp_pre_08?

  include EventedSpec::AMQPBackports
end
