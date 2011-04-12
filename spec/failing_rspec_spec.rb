require 'spec_helper'

describe 'Following 9 examples should all be failing:' do
  describe EventMachine, " when running failing examples" do
    include EventedSpec::EMSpec

    it "should not bubble failures beyond rspec" do
      EM.add_timer(0.1) do
        :should_not_bubble.should == :failures
        done
      end
    end

    it "should not block on failure" do
      1.should == 2
    end
  end

  describe EventMachine, " when testing with EventedSpec::EMSpec with a maximum execution time per test" do
    include EventedSpec::EMSpec

    default_timeout 1

    it 'should timeout before reaching done' do
      EM.add_timer(2) { done }
    end

    it 'should timeout before reaching done' do
      timeout(0.3)
      EM.add_timer(0.6) { done }
    end
  end

  describe AMQP, " when testing with EventedSpec::AMQPSpec with a maximum execution time per test" do

    include EventedSpec::AMQPSpec

    default_timeout 1

    it 'should timeout before reaching done' do
      EM.add_timer(2) { done }
    end

    it 'should timeout before reaching done' do
      timeout(0.2)
      EM.add_timer(0.5) { done }
    end

    it 'should fail due to timeout, not hang up' do
      timeout(0.2)
    end

    it 'should fail due to default timeout, not hang up' do
    end
  end

  describe AMQP, "when default timeout is not set" do
    include EventedSpec::AMQPSpec
    it "should fail by timeout anyway" do
      1.should == 1
    end
  end
end