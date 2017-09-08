require "threadify/version"
require 'concurrent'
require 'forwardable'


module Threadify

  # A couple classes to represent non-normal
  # exits

  class Break; end
  class Return
    attr_reader :value
    def initialize(val)
      @value = val
    end
  end

  # Grab all the necessary info from
  # an error for reporting and re-raising
  class Error
    attr_reader :args, :error

    def initialize(args, error)
      @args  = args
      @error = error
    end
  end

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

    def initialize(max_size: Concurrent.processor_count * 4)
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


  class Enumerator

    include Enumerable

    def self.from(enum)
      self.new(enum).enum_for(:each)
    end

    def executor(threads: 5, max_queue: 15)
      Concurrent::ThreadPoolExecutor.new(
        fallback_policy: :caller_runs,
        min_threads:     threads,
        max_threads:     threads,
        max_queue:       max_queue
      )
    end

    def initialize(enumerable, max_queue: nil, threads: Concurrent.processor_count)
      max_queue ||= threads * 5
      @enum     = enumerable
      @q        = PromiseQueue.new(max_size: max_queue)
      @executor = self.executor(threads: threads, max_queue: max_queue)
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

