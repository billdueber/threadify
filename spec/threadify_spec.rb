require "spec_helper"

RSpec.describe Threadify::Enumerator do

  include_context "shared stuff" # in file spec/shared_stuff.rb

  it "has a version number" do
    expect(Threadify::VERSION).not_to be nil
  end


  describe "other enumerable methods" do

    it "can inject with order-independent code" do
      skip
      expect(te.inject(&:+)).to be(enum.sum)
    end

    it "can count" do
      expect(te.count).to be(enum.count)
    end

    it "does each_with_index" do
      # skip "Need to do this one 'by hand' as well. The index is shared memory"
      ewi = Threadify::Enumerator.new(1..10)
      a = []
      ewi.each_with_index {|v, i| a << [v, i + 1] }
      expect(a).to eq((1..10).map{|x| [x, x]})
    end

  end

end
