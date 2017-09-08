require 'concurrent'

module Threadify
  class Executor
    def self.new(threads: 5, max_queue: threads * 5)
      Concurrent::ThreadPoolExecutor.new(
        fallback_policy: :caller_runs,
        min_threads:     threads,
        max_threads:     threads,
        max_queue:       max_queue
      )
    end
  end

  # An executor with thread/queue sizes good for CPU-bound tasks
  class CPUExecutor < Executor
    def self.new(threads: Concurrent.processor_count, max_queue: Concurrent.processor_count * 2)
      super
    end
  end

  # An executor with thread/queue sizes good for IO-bound (i.e., lots of waiting) tasks
  class IOBoundExecutor < Executor
    def self.new(threads: Concurrent.processor_count * 5, max_queue: Concurrent.processor_count * 5)
      super
    end
  end
end
