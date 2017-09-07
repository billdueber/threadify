require "threadify/version"
require 'concurrent'
require 'forwardable'


module Threadify

  class Break;
  end

  class Error
    attr_reader :args, :error

    def initialize(args, error)
      @args  = args
      @error = error
    end
  end

  class PromiseQueue

    extend Forwardable

    def_delegators :@q, :push, :shift, :first, :size, :empty?, :each, :map

    def initialize
      @q = Concurrent::Array.new
    end

    def full?
      size > 4
    end

    def next_or_raise
      val = self.next

      if val == 'ddddd'
        raise "oops!"
      else
        val
      end
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

    def executor
      Concurrent::ThreadPoolExecutor.new(
        fallback_policy: :caller_runs,
        max_threads:     5,
        max_queue:       10
      )
    end

    def initialize(enumerable)
      @enum     = enumerable
      @q        = PromiseQueue.new
      @executor = self.executor
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
        :borken
      else
        val
      end
    end

    def map(&blk)
      rv = []
      self.each(blk, do_yield: true) {|x| rv << x}
      rv
    end



    def each(block = nil, do_yield: false, &blk)
      @block   = (block or blk)
      last_val = nil
      catch :break do
        @enum.each do |x|
          while @q.values_ready?
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

    end

  end
end


te = Threadify::Enumerator.new(1..10)

def hello
  te.each do |x|
    sleep(0.1)
    return "hello" if x == 8
  end
end

x = hello
puts x

