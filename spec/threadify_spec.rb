require "spec_helper"

RSpec.describe Threadify::Enumerator do

  include_context "shared stuff" # in file spec/shared_stuff.rb

  it "has a version number" do
    expect(Threadify::VERSION).not_to be nil
  end


  describe "other enumerable methods" do

    it "can inject with order-independent code" do
      expect(te.inject(&:+)).to be(enum.sum)
    end

    it "can count" do
      expect(te.count).to be(enum.count)
    end

  end

end
