
require "ext/algorithm.rb"

describe "Algorithm" do
  describe "::follow" do
    let(:node_klass) {
      Class.new do
        attr_reader :name
        attr_reader :parent
        attr_reader :children

        def initialize(name, parent)
          @name = name
          @parent = parent
          @children = []
          parent.children << self if parent
        end
      end
    }

    let(:r) { node_klass.new("r", nil) }
    let(:d1) { node_klass.new("d1", r) }
    let(:d2) { node_klass.new("d2", d1) }
    let(:d3) { node_klass.new("d3", d2) }
      
    it "produces a list of objects chained by a member" do
      expect(Algorithm.follow(d3, :parent)).to eq [d3, d2, d1, r]
    end
  end
end
