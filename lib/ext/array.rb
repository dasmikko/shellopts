
module XArray
  refine Array do
    # Find and return first duplicate. Return nil if not found
    def find_dup
      detect { |e| rindex(e) != index(e) }
    end
  end
end
