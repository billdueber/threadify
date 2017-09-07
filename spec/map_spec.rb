require 'spec_helper'

RSpec.describe "Threadify::Enumerator#map basics" do
  include_context "shared stuff" # in file spec/shared_stuff.rb

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
      sleep(wait_time) if x == slow_value
      a << x
      x + 1
    end
    expect(map_result.size).to equal(enum.size)
    expect(a.last).to equal(slow_value)

    expect(map_result).to eq(unthreaded_result)
  end
end
