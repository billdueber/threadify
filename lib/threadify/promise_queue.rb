require 'concurrent'
require 'forwardable'

module Threadify

  # A simple abstraction over an array that allows
  # us to determine what the state of the pending
  # promises are. We can't use a regular ruby Queue
  # because it's important that we can peek
  # at the first value without popping it off
  # the stack or blocking
  class PromiseQueue

    # We only need a few methods from array, so we'll just use those
    # to avoid getting an enormous surface area

    extend Forwardable
    def_delegators :@q, :push, :shift, :first, :size, :empty?, :each, :map

    def initialize(max_size:)
      @q        = [] # Concurrent::Array.new
      @max_size = max_size
    end

    def full?
      size > @max_size
    end

    def values_ready?
      !@q.empty? and @q.first.complete?
    end

    def errored?
      !@q.empty? and @q.first.rejected?
    end

    def error
      @q.first.reason
    end

    def next
      p = self.shift
      p.value
    end

  end


end
