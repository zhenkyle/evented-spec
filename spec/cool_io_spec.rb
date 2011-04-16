require 'spec_helper'

describe EventedSpec::SpecHelper, "Cool.io bindings", :nojruby => true do
  include EventedSpec::SpecHelper
  default_timeout 0.1
  let(:event_loop) { Coolio::Loop.default }

  def coolio_running?
    event_loop.instance_variable_get(:@running)
  end # coolio_running?

  after(:each) {
    coolio_running?.should be_false
  }

  describe "sanity check:" do
    it "we should not be in cool.io loop unless explicitly asked" do
      coolio_running?.should be_false
    end
  end

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
      }.to raise_error(EventedSpec::SpecHelper::SpecTimeoutExceededError)
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

  describe "hooks" do
    context "coolio_before" do
      coolio_before do
        @called_back = true
        coolio_running?.should be_true
        Coolio::Loop.default.has_active_watchers?.should be_true
      end

      it "should run before example starts" do
        coolio do
          @called_back.should be_true
          done
        end
      end
    end

    context "coolio_after" do
      coolio_after do
        @called_back = true
        coolio_running?.should be_true
        Coolio::Loop.default.has_active_watchers?.should be_true
      end

      it "should run after example finishes" do
        coolio do
          @called_back.should be_false
          done
        end
        @called_back.should be_true
      end
    end
  end

  describe EventedSpec::CoolioSpec do
    include EventedSpec::CoolioSpec
    it "should run inside of coolio loop" do
      coolio_running?.should be_true
      Coolio::Loop.default.has_active_watchers?.should be_true
      done
    end
  end
end
