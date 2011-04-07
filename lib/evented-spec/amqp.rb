# Monkey patching some methods into AMQP to make it more testable
module AMQP
  # Initializes new AMQP client/connection without starting another EM loop
  def self.start_connection(opts={}, &block)
    self.connection = connect opts, &block
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
end