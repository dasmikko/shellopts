
module Ext
  module Array
    module ShiftWhile
      refine ::Array do
        def shift_while(&block)
          r = []
          while value = self.first
            break if !block.call(value)
            r << self.shift
          end
          r
        end
      end
    end
  end
end

