module Threadify

  # A couple classes to represent non-normal
  # exits

  class BreakFlow
    attr_reader :type, :args, :error
    def initialize(type, args, error)
      @type = type
      @error = error
    end
  end


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
end
