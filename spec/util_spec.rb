require "spec_helper"

describe EventedSpec::Util do
  describe ".deep_clone" do
    context "for non-clonables" do
      it "should return the argument" do
        described_class.deep_clone(nil).object_id.should   == nil.object_id
        described_class.deep_clone(0).object_id.should     == 0.object_id
        described_class.deep_clone(false).object_id.should == false.object_id
      end
    end

    context "for strings and other simple clonables" do
      let(:string) { "Hello!" }
      it "should return a clone" do
        clone = described_class.deep_clone(string)
        clone.should == string
        clone.object_id.should_not == string.object_id
      end
    end

    context "for arrays" do
      let(:array) { [child_hash, child_string] }
      let(:child_string) { "Hello!" }
      let(:child_hash) { {} }
      it "should return a deep clone" do
        clone = described_class.deep_clone(array)
        clone.should == array
        clone.object_id.should_not == array.object_id
        clone[0].object_id.should_not == child_hash.object_id
        clone[1].object_id.should_not == child_string.object_id
      end
    end

    context "for hash" do
      let(:hash) {
        {:child_hash => child_hash, :child_array => child_array}
      }
      let(:child_hash) { {:hello => "world"} }
      let(:child_array) { ["One"] }

      it "should return a deep clone" do
        clone = described_class.deep_clone(hash)
        clone.should == hash
        clone.object_id.should_not == hash.object_id
        clone[:child_hash].object_id.should_not == child_hash.object_id
        clone[:child_array].object_id.should_not == child_array.object_id
      end
    end
  end
end