require 'spec_helper'


describe EventedSpec::SpecHelper, "Cool.io bindings" do
  include EventedSpec::SpecHelper
  default_timeout 0.1
  let(:event_loop) { Coolio::Loop.default }

  after(:each) {
    event_loop.instance_variable_get(:@running).should be_false
  }

  describe "#coolio" do
    it "should execute given block in the right scope" do
      coolio do
        @variable = true
        done
      end
      @variable.should be_true
    end

    it "should start default cool.io loop and give control" do
      coolio do
        event_loop.instance_variable_get(:@running).should be_true
        done
      end
    end

    it "should stop the event loop afterwards" do
      coolio do
        @do_something_useful = true
        done
      end
      event_loop.instance_variable_get(:@running).should be_false
    end

    it "should raise SpecTimeoutExceededError when #done is not issued" do
      expect {
        coolio do
        end
      }.to raise_error(SpecTimeoutExceededError)
    end

    it "should propagate mismatched rspec expectations" do
      expect {
        coolio do
          :fail.should == :win
        end
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end


  describe "#done" do
    it "should execute given block" do
      coolio do
        done(0.05) do
          @variable = true
        end
      end
      @variable.should be_true
    end

    it "should cancel timeout" do
      expect {
        coolio do
          done(0.2)
        end
      }.to_not raise_error
    end
  end
end