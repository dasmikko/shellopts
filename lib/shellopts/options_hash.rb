require "shellopts"

module ShellOpts
  class OptionsHash
    def initialize(shellopts)
      @hash = {}
      assign_hash(@hash, shellopts)
    end


  # a         true
  # +a        [true, true, ...]
  # a=        arg
  # +a=       [arg1, arg2, ...]
  # a=?       arg or nil
  # +a=?      [arg1, nil, ...]
            
    def user(key) end
    def count(key) Array(self[key]).size end
    def key?(key) @hash.key?(key) end
    def [](key) @hash[key] end
    def default(key, default_value) key?(key) ? self[key] : default_value end

  private
    def assign_hash(hash, shellopts)
      ast = shellopts.ast
      while ast
        for option in ast.options
          grammar = option.grammar
          value = grammar.argument? ? option.value : true
          if !hash.key?(option.name) # Only true first this option is processed
            value = [value] if grammar.repeated?
            for key in grammar.short_names + grammar.long_names
              hash[key] = value
            end
          else # Only happens if repeated?
            hash[key] << value
          end
        end
        if ast = ast.command
          hash[ast.name] = {}
          hash = hash[ast.name]
        end
      end
    end
  end
end
