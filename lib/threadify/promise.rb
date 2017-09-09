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
    def fill(v, i)
      @val = v
      @i   = i
      self
    end
  end

  class Promise
    def self.from(args:, index: , executor:, block:)
      emptyvi = VI.new
      Concurrent::Promise.execute(executor: executor, args: [block, emptyvi, args, index]) do |b, vi, y, i|
        vi.fill(evaluate_in_promise(b, y, i), i)
        # vi.fill(1,1)
        vi
      end
    end

    def self.evaluate_in_promise(block, y, i)
      v = block.call(y,i)
      v
    rescue LocalJumpError => e
      #:break, :redo, :retry, :next, :return, or :noreason
      BreakFlow.new(e.reason, args, e)
    rescue => e
      Error.new(args, e)
    end
  end

end
