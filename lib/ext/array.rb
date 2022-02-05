
module Ext
  module Array
    module ShiftWhile
      refine ::Array do
        # The algorithm ensures that the block sees the array as if the current
        # element has already been removed
        def shift_while(&block)
          r = []
          while value = self.shift
            if !block.call(value)
              self.unshift value
              break
            else
              r << value
            end
          end
          r

#         while value = self.first
#           break if !block.call(value)
#           r << self.shift
#         end
#         r
        end
      end
    end
  end
end

