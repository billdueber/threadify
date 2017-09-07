require "spec_helper"

def sleep_a_bit(n)
  sleep(1.0 - (1.0 / n))
end

t = Threadify::Enumerator.new(5..9)


RSpec.describe Threadify::Enumerator do
  it "has a version number" do
    expect(Threadify::VERSION).not_to be nil
  end


  describe '#each' do
    let(:te) { Threadify::Enumerator.new(1..10)}
    it "runs all the items" do
      a = []
      te.each {|x| a << x}
      expect(a.size).to equal(10)
    end

    it "doesn't preserve order" do
      a = []
      te.each {|x| sleep(0.5) if x == 8; a << x}
      expect(a.size).to equal(10)
      expect(a.last).to equal(8)
    end

  end


end
