require 'benchmark'
RSpec.describe "Threadify concurrancy" do

  include_context "shared stuff" # in file spec/shared_stuff.rb
  
  it "runs N x-second sleeps in about x seconds where N < #threads" do
    fiver    = Threadify::Enumerator.new(1..(threads - 1))
    realtime = Benchmark.realtime {fiver.each {|x| sleep(wait_time)}}
    expect(realtime).to be_within(0.02).of(wait_time)
  end

  it "takes longer if the threads run out" do
    longer = Threadify::Enumerator.new(1..(threads * 3 - 1))
    realtime = Benchmark.realtime {longer.each {|x| sleep(wait_time)}}
    expect(realtime).to be_within(0.02).of(3 * wait_time)
  end

  it "takes longer if the queue is short" do
    shortqueue = Threadify::Enumerator.new(enum, max_queue: 4)
    normal_realtime = Benchmark.realtime {te.each {|x| sleep(wait_time)}}
    shortqueue_realtime = Benchmark.realtime {shortqueue.each {|x| sleep(wait_time)}}
    expect(shortqueue_realtime.to_f - normal_realtime).to be_within(0.05).of(wait_time)

  end
end
