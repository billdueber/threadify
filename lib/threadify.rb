require "threadify/version"
require 'threadify/errors'
require 'threadify/promise_queue'
require 'threadify/promise'
require 'threadify/executor'

require 'concurrent'


module Threadify

  class Enumerator

    include Enumerable





    def initialize(enumerable, max_queue: Concurrent.processor_count * 5, executor: nil, threads: Concurrent.processor_count)
      max_queue ||= threads * 5
      @enum     = enumerable
      @q        = PromiseQueue.new(max_size: max_queue)
      @executor = executor || IOBoundExecutor.new(threads: threads)
    end

    # Enumerable#count can't be parallelized, so
    # we'll fake it
    def count
      @enum.count
    end

    # Enumerable#inject also isn't so hot, so
    # we'll fake *that*, too
    #
    # Geez. So many argument combinations :-(
    # https://ruby-doc.org/core-2.4.1/Enumerable.html#method-i-inject
    #
    # inject(initial_value = first_value, symbol=nil, &blk)

    def inject(obj = self.object_id, &blk)
      raise "Bit the bullet and implement this"
    end



    def map(&blk)
      rv = []
      self.ewi(blk, do_yield: true) {|x, _| rv << x}
      rv
    end

    def each(&blk)
      self.ewi(blk) {|x, i| x }
    end


    # We'll do everything via each_with_index because the index that
    # get passed along is mutable if we just go through #each. Instead,
    # just implement #each in terms of #each_with_index and throw away
    # the index when yielding

    def each_with_index(&blk)
      self.ewi(blk) {|x, i| x }
    end

    def ewi(block = nil, do_yield: true, &blk)
      @block   = (block or blk)
      last_val = nil
      catch :break do
        @enum.each_with_index do |x, i|
          while @q.values_ready? or @q.full?
            last_val = @q.force_next_evaluation
            if do_yield
              yield last_val.val, last_val.i
            end
          end
          @q.push Threadify::Promise.from(args: x, index: i, executor: @executor, block: @block)
        end
      end

      # Find the last valid value and return it
      # Will raise if it needs raising
      catch :break do
        until @q.empty?
          last_val = @q.force_next_evaluation
          if do_yield
            yield last_val.val, last_val.i
          end
        end
      end
      last_val.val
    ensure
      @executor.shutdown
      @executor.wait_for_termination
    end

  end
end

