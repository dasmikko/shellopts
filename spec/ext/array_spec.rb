require "spec_helper.rb"

describe "XArray" do
  describe "#find_dup" do
    using XArray

    it "returns the first duplicate element" do
      a = [1, 2, 3, 4, 3, 5]
      expect(a.find_dup).to eq 3
    end
    it "returns nil if not found" do
      a = []
      expect(a.find_dup).to eq nil
      a = [1, 2, 3]
      expect(a.find_dup).to eq nil
    end
  end
end
