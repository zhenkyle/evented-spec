require 'spec_helper'

def publish_and_consume_once(queue_name="test_sink", data="data")
  amqp(:spec_timeout => 0.5) do
    AMQP::Channel.new do |channel, _|
      exchange = channel.direct(queue_name)
      queue = channel.queue(queue_name).bind(exchange)
      queue.subscribe do |hdr, msg|
        hdr.should be_an AMQP::Header
        msg.should == data
        done { queue.unsubscribe; queue.delete }
      end
      EM.add_timer(0.2) do
        exchange.publish data
      end
    end
  end
end

describe RSpec do
  it 'should work as normal without AMQP-Spec' do
    1.should == 1
  end
end

describe 'Evented AMQP specs' do
  describe AMQP, " when testing with EventedSpec::SpecHelper" do
    include EventedSpec::SpecHelper

    default_options AMQP_OPTS if defined? AMQP_OPTS
    default_timeout 1

    puts "Default timeout: #{default_timeout}"
    puts "Default options :#{default_options}"

    it_should_behave_like 'SpecHelper examples'

    context 'inside embedded context / example group' do
      it_should_behave_like 'SpecHelper examples'
    end
  end

  describe AMQP, " when testing with EventedSpec::AMQPSpec" do
    include EventedSpec::AMQPSpec

    default_options AMQP_OPTS if defined? AMQP_OPTS
    default_timeout 1

    it_should_behave_like 'Spec examples'

    context 'inside embedded context / example group' do
      it 'should inherit default_options/metadata from enclosing example group' do
        # This is a guard against regression on dev box without notice
        AMQP.connection.instance_variable_get(:@settings)[:host].should == AMQP_OPTS[:host]
        self.class.default_options[:host].should == AMQP_OPTS[:host]
        self.class.default_timeout.should == 1
        done
      end

      it_should_behave_like 'Spec examples'
    end
  end

  describe AMQP, " tested with EventedSpec::SpecHelper when Rspec failures occur" do
    include EventedSpec::SpecHelper

    default_options AMQP_OPTS if defined? AMQP_OPTS

    it "bubbles failing expectations up to Rspec" do
      expect {
        amqp do
          :this.should == :fail
        end
      }.to raise_error RSpec::Expectations::ExpectationNotMetError
      AMQP.connection.should == nil
    end

    it "should NOT ignore failing expectations after 'done'" do
      expect {
        amqp do
          done
          :this.should == :fail
        end
      }.to raise_error RSpec::Expectations::ExpectationNotMetError
      AMQP.connection.should == nil
    end

    it "should properly close AMQP connection after Rspec failures" do
      AMQP.connection.should == nil
    end
  end

  describe 'MQ', " when AMQP.queue/fanout/topic tries to access Thread.current[:mq] across examples" do
    include EventedSpec::SpecHelper

    default_options AMQP_OPTS if defined? AMQP_OPTS

    it 'sends data to the queue' do
      publish_and_consume_once
    end

    it 'does not hang sending data to the same queue, again' do
      publish_and_consume_once
    end

    it 'cleans Thread.current[:mq] after pubsub examples' do
      Thread.current[:mq].should be_nil
    end
  end
end

describe RSpec, " when running an example group after another group that uses AMQP-Spec " do
  it "should work normally" do
    :does_not_hang.should_not be_false
  end
end