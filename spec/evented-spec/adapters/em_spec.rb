require 'spec_helper'

describe EventedSpec::SpecHelper, "EventMachine bindings" do
  include EventedSpec::SpecHelper
  default_timeout 0.5

  def em_running?
    EM.reactor_running?
  end # em_running?

  after(:each) {
    em_running?.should be_false
  }

  let(:method_name) { "em" }
  let(:prefix) { "em_" }

  it_should_behave_like "EventedSpec adapter"


  describe EventedSpec::EMSpec do
    include EventedSpec::EMSpec
    it "should run inside of em loop" do
      em_running?.should be_true
      done
    end
  end

end
