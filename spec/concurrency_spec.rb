require 'benchmark'
RSpec.describe "Threadify concurrancy" do

  include_context "shared stuff" # in file spec/shared_stuff.rb

  it "runs about the same with one thread" do
    onethread = Threadify::Enumerator.new(enum, threads: 1)
    nonthreaded = Benchmark.realtime { enum.each{|x| sleep 0.05}}
    threaded = Benchmark.realtime { onethread.each{|x| sleep 0.05}}
    expect(nonthreaded).to be_within(nonthreaded * 0.10).of(threaded)
  end

  it "runs faster with two threads" do
    twothreads = Threadify::Enumerator.new(enum, threads: 2)
    nonthreaded = Benchmark.realtime { enum.each{|x| sleep 0.05}}
    threaded = Benchmark.realtime { twothreads.each{|x| sleep 0.05}}
    expect(nonthreaded).to be_within(nonthreaded * 0.10).of(2 * threaded)
  end
  
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
