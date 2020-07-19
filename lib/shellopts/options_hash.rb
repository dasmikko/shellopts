require "shellopts"

module ShellOpts
  class OptionsHash
    def initialize(ast)
      @hash = {}
      @node_hash = {}
      for option in ast.options
        grammar = option.grammar
        value = grammar.argument? ? option.value : true
        if !@hash.key?(option.name) # Only true first this option is processed
          if grammar.repeated?
            value = [value]
            node = [option]
          end
          for key in grammar.short_names + grammar.long_names
            @hash[key] = value
            @node_hash[key] = node
          end
        else # Only happens if repeated?
          @hash[key] << value
          @node_hash[key] << node
        end
      end
      if ast = ast.command
        @hash[ast.name] = @node_hash[ast.name] = OptionsHash.new(ast)
      end
    end

    def user(key) end
    def count(key) Array(self[key]).size end
    def key?(key) @hash.key?(key) end
    def [](key) @hash[key] end
    def default(key, default_value) key?(key) ? self[key] : default_value end
    def node(key, index = 0) end
  end
end

__END__
module ShellOpts
  class OptionsHash
    def initialize(ast)
      @hash = {}
      assign_hash(@hash, ast)
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
    def [](key) @hash[key]&.last end
    def default(key, default_value) key?(key) ? self[key] : default_value end

  private
    def assign_hash(hash, ast)
      for option in ast.options
        grammar = option.grammar
        value = grammar.argument? ? option.value : true
        if !hash.key?(option.name) # Only true first this option is processed
          value = [value] if grammar.repeated?
          for key in grammar.short_names + grammar.long_names
            hash[key] = [option.name, value]
          end
        else # Only happens if repeated?
          hash[key].last << value
        end
      end
      if ast = ast.command
        hash[ast.name] = OptionsHash.new(ast)
        hash = hash[ast.name].last
      end
      hash
    end
  end
end
