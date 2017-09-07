require "spec_helper"
require 'benchmark'

def sleep_a_bit(n)
  sleep(1.0 - (1.0 / n))
end

RSpec.describe Threadify::Enumerator do

  let(:enum) {5..15}
  let(:last_value) {15}
  let(:slow_value) {8}
  let(:te) {Threadify::Enumerator.new(enum)}


  it "has a version number" do
    expect(Threadify::VERSION).not_to be nil
  end


  describe '#each basics' do
    it "runs all the items" do
      a = []
      te.each {|x| a << x}
      expect(a.size).to equal(enum.size)
    end

    it "doesn't preserve order" do
      a = []
      te.each {|x| sleep(0.5) if x == slow_value; a << x}
      expect(a.size).to equal(enum.size)
      expect(a.last).to equal(slow_value)
    end

    it "returns the last value regardless of run order" do
      a    = []
      lval = te.each {|x| sleep(0.5) if x == slow_value; a << x; x}
      expect(a.last).to be(slow_value)
      expect(lval).to be(last_value)
    end

  end

  describe "#map basics" do
    it "returns all the items" do
      expect(te.map {|x| x + 3}.size).to equal(enum.size)
    end

    it "returns them in order" do
      unthreaded = enum.map {|x| x + 2}
      expect(te.map {|x| x + 2}).to eq(unthreaded)
    end

    it "runs them out of order" do
      a                 = []
      unthreaded_result = enum.map do |x|
        a << x
        x + 1
      end

      map_result = te.map do |x|
        sleep(0.5) if x == slow_value
        a << x
        x + 1
      end
      expect(map_result.size).to equal(enum.size)
      expect(a.last).to equal(slow_value)

      expect(map_result).to eq(unthreaded_result)
    end
  end

  describe "runs concurrently" do
    it "runs N 1-second sleeps in about 1 second where N < #threads" do
      fiver    = Threadify::Enumerator.new(1..4)
      realtime = Benchmark.realtime {fiver.each {|x| sleep(1)}}
      expect(realtime).to be_within(0.02).of(1.0)
    end
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
