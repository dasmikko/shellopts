
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
        end
      end
    end

    module Wrap
      refine ::Array do
        # Concatenate strings into lines that are at most +width+ characters wide
        def wrap(width, curr = 0)
          lines = [[]]
          each { |word|
            if curr + 1 + word.size < width
              lines.last << word
              curr += 1 + word.size
            else
              lines << [word]
              curr = word.size
            end
          }
          lines.map! { |words| words.join(" ") }
        end
      end
    end
  end
end
