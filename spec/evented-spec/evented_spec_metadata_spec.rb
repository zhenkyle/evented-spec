require 'spec_helper'

describe "Example Groups", ".evented_spec_metadata" do
  context "when EventedSpec::SpecHelper is included" do
    include EventedSpec::SpecHelper
    it "should assign some hash by default" do
      self.class.evented_spec_metadata.should == {}
    end

    context "in nested group" do
      evented_spec_metadata[:nested] = {}
      evented_spec_metadata[:other] = :value
      it "should merge metadata" do
        self.class.evented_spec_metadata.should == {:nested => {}, :other => :value}
      end

      context "in deeply nested group" do
        evented_spec_metadata[:nested][:deeply] = {}
        evented_spec_metadata[:other] = "hello"
        it "should merge metadata" do
          self.class.evented_spec_metadata[:nested][:deeply].should == {}
        end

        it "should allow to override merged metadata" do
          self.class.evented_spec_metadata[:other].should == "hello"
        end
      end

      context "in other deeply nested group" do
        evented_spec_metadata[:nested][:other] = {}
        it "should diverge without being tainted by neighbouring example groups" do
          self.class.evented_spec_metadata.should == {:nested => {:other => {}}, :other => :value}
        end
      end
    end
  end

  context "when EventedSpec::SpecHelper is not included" do
    it "should not be defined" do
      self.class.should_not respond_to(:evented_spec_metadata)
    end
  end
end