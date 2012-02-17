require "spec_helper"

describe "EventedSpec AMQP bindings" do
  include EventedSpec::SpecHelper
  default_timeout 0.5

  def amqp_running?
    EM.reactor_running? && !!AMQP.connection
  end # amqp_running?


  it "runs after amqp is connected" do
    amqp_running?.must_equal false
    amqp do
      amqp_running?.must_equal true
      done
    end
    amqp_running?.must_equal false
  end

  describe "hooks" do
    def hooks
      @hooks ||= []
    end

    before { hooks << :before }
    em_before { hooks << :em_before }
    amqp_before { hooks << :amqp_before }
    amqp_after { hooks << :amqp_after }
    em_after { hooks << :em_after }
    after { hooks << :after }

    it "execute in proper order" do
      hooks.must_equal [:before]
      amqp do
        hooks.must_equal [:before, :em_before, :amqp_before]
        done
      end
      hooks.must_equal [:before, :em_before, :amqp_before,
                        :amqp_after, :em_after]
    end
  end

  describe EventedSpec::AMQPSpec do
    include EventedSpec::AMQPSpec

    it "runs after amqp is connected" do
      amqp_running?.must_equal true
      done
    end
  end

  describe "actual amqp functionality" do
    def publish_and_consume_once(queue_name="test_sink", data="data")
      AMQP::Channel.new do |channel, _|
        exchange = channel.direct(queue_name)
        queue = channel.queue(queue_name).bind(exchange)
        queue.subscribe do |hdr, msg|
          hdr.must_be_kind_of AMQP::Header
          msg.must_equal data
          done { queue.unsubscribe; queue.delete }
        end
        EM.add_timer(0.2) do
          exchange.publish data
        end
      end
    end

    it "can connect and publish something" do
      amqp do
        publish_and_consume_once
      end
    end
  end
end
