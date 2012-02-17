require 'spec_helper'

describe EventedSpec do
  describe "inclusion of helper modules" do
    include EventedSpec::SpecHelper

    it "creates reactor launchers" do
      [:em, :amqp, :coolio].each do |method|
        self.respond_to?(method).must_equal true
      end
    end

    it "adds various helpers" do
      [:done, :timeout, :delayed].each do |method|
        self.must_respond_to method
      end
    end

    it "creates hooks and other group helpers" do
      [:em_before, :em_after, :amqp_before,
       :amqp_after, :coolio_before, :coolio_after,
       :default_timeout, :default_options].each do |method|
        self.class.must_respond_to method
      end
    end

    describe "propagation to sub contexts" do
      it "should work" do
        [:em, :amqp, :coolio].each do |method|
          self.must_respond_to method
        end

        [:done, :timeout, :delayed].each do |method|
          self.must_respond_to method
        end

        [:em_before, :em_after, :amqp_before,
         :amqp_after, :coolio_before, :coolio_after,
         :default_timeout, :default_options].each do |method|
          self.class.must_respond_to method
        end
      end
    end
  end
end
