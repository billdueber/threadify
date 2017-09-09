require 'concurrent'
require 'threadify/errors'
module Threadify

  # A Threadify::Promise is a promise that has several possible outcomes.
  #  - the value
  #  - a Threadify::Return object showing that we want to break out of the
  #    loop _right now_ and return the given value from the calling method
  #  - a Threadify::Break object that just says to break out of the loop
  #    and then continue running the rest of the calling method

  class VI
    attr_reader :val, :i
    def initialize(v, i)
      @val = v
      @i   = i
    end
  end

  class Promise
    def self.from(args:, index: , executor:, block:)
      Concurrent::Promise.execute(executor: executor, args: [args, index.dup]) do |a|
        y,i = *a
        VI.new(evaluate_in_promise(block, y), i)
      end
    end

    def self.evaluate_in_promise(block, args)
      block.call(args)
    rescue LocalJumpError => e
      #:break, :redo, :retry, :next, :return, or :noreason
      BreakFlow.new(e.reason, y, e)
    rescue => e
      Error.new(y, e)
    end
  end

end
