require 'spec_helper'

describe "EventedSpec EventMachine bindings" do
  include EventedSpec::SpecHelper
  default_timeout 0.5

  it "can run inside of em loop" do
    EM.reactor_running?.must_equal false
    em do
      EM.reactor_running?.must_equal true
      done
    end
    EM.reactor_running?.must_equal false
  end

  describe "hooks" do
    def hooks
      @hooks ||= []
    end

    before { hooks << :before }
    em_before { hooks << :em_before }
    em_after { hooks << :em_after }
    after { hooks << :after }

    it "execute in proper order" do
      hooks.must_equal [:before]
      em do
        hooks.must_equal [:before, :em_before]
        done
      end
      hooks.must_equal [:before, :em_before, :em_after]
    end
  end

  describe "#delayed" do
    default_timeout 0.7
    it "works as intended" do
      em do
        time = Time.now
        delayed(0.3) { Time.now.must_be_close_to time + 0.3, 0.1 }
        done(0.4)
      end
    end
  end

  describe EventedSpec::EMSpec do
    include EventedSpec::EMSpec
    it "wraps the whole example" do
      EM.reactor_running?.must_equal true
      done
    end
  end
end
