
module ShellOpts
  class Args < Array
    def initialize(shellopts, *args)
      @shellopts = shellopts
      super(*args)
    end

    # Remove and return +count+ elements from the beginning of the array.
    # Elements are removed from the end of the array if +count+ is less than 0.
    # Expects at least +count.abs+ elements in the array
    def extract(count, message = nil) 
      self.size >= count.abs or inoa(message)
      start = count >= 0 ? 0 : size + count
      slice!(start, count.abs)
    end

    # Shifts +count+ elements from the array. Expects exactly +count+ elements
    # in the array
    def expect(count, message = nil) 
      self.size == count or inoa(message)
      self
    end

    # Eats rest of the elements. Expects at least +min+ elements
    def consume(count, message = nil) 
      self.size >= count or inoa(message)
      self
    end

  private
    def inoa(message = nil) 
      @shellopts.messenger.error(message || "Illegal number of arguments") 
    end
  end
end
