require "threadify/version"
require 'threadify/errors'
require 'threadify/promise_queue'
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

    def callify(x)
      @block.call(x)
    end

    def promise(x)
      Concurrent::Promise.execute(executor: @executor, args: x) do |y|
        begin
          val = callify(y);
          val
        rescue LocalJumpError
          Break.new
        rescue => e
          Error.new(x, e)
        end
      end
    end

    def pull_a_value
      val = @q.next
      case val
      when Threadify::Error
        raise val.error, val.error.message, val.error.backtrace
      when Threadify::Break
        throw :break
      else
        val
      end
    end

    def map(&blk)
      rv = []
      self.each(blk, do_yield: true) {|x| rv << x}
      rv
    end

    # need to work around each_with_index a little bit
    def each_with_index(&blk)
      index =  Concurrent::AtomicFixnum.new(-1)
      identity = Proc.new{|x| [x, index.increment]}
      self.each(identity, do_yield: true, &blk)
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


    def each(block = nil, do_yield: false, &blk)
      @block   = (block or blk)
      last_val = nil
      catch :break do
        @enum.each do |x|
          while @q.values_ready? or @q.full?
            last_val = pull_a_value
            if do_yield
              yield last_val
            end
          end
          @q.push promise(x)
        end
      end

      # Find the last valid value and return it
      # Will raise if it needs raising
      catch :break do
        until @q.empty?
          last_val = pull_a_value
          if do_yield
            yield last_val
          end
        end
      end
      last_val
    ensure
      @executor.shutdown
      @executor.wait_for_termination
    end

  end
end

