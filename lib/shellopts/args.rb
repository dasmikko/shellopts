
module ShellOpts
  # Specialization of Array for arguments lists. Args extends Array with a
  # #extract and an #expect method to extract elements from the array. The
  # methods call #error() in response to errors
  class Args < Array
    def initialize(shellopts, *args)
      @shellopts = shellopts
      super(*args)
    end

    # Remove and return elements from beginning of the array. If
    # +count_or_range+ is a number, that number of elements will be returned.
    # If the count is one, a simple value is returned instead of an array.  If
    # the count is negative, the elements will be removed from the end of the
    # array. If +count_or_range+ is a range, the number of elements returned
    # will be in that range. The range can't contain negative numbers #expect
    # calls #error() if there's is not enough elements in the array to satisfy
    # the request
    def extract(count_or_range, message = nil) 
      if count_or_range.is_a?(Range)
        range = count_or_range
        range.min <= self.size or inoa(message)
        n_extract = [self.size, range.max].min
        n_extend = range.max > self.size ? range.max - self.size : 0
        r = self.shift(n_extract) + Array.new(n_extend)
      else
        count = count_or_range
        self.size >= count.abs or inoa(message)
        start = count >= 0 ? 0 : size + count
        r = slice!(start, count.abs)
        r.size == 0 ? nil : (r.size == 1 ? r.first : r)
      end
    end

    # As extract except it doesn't allow negative counts and that the array is
    # expect to be emptied by the operation
    def expect(count_or_range, message = nil)
      r = extract(count_or_range, message)
      self.empty? or inoa
      r
    end

  private
    def inoa(message = nil) 
      @shellopts.messenger.error(message || "Illegal number of arguments") 
    end
  end
end
