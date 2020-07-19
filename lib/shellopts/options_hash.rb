require "shellopts"

module ShellOpts
  class OptionsHash
    def initialize(ast)
      @hash = {} # Hash from Ast#name to [ast_node, option_value]
      for option in ast.options
        grammar = option.grammar
        value = grammar.argument? ? option.value : true
        if !@hash.key?(option.name) # Only true first this option is processed
          if grammar.repeated?
            value = [value]
          end
          hash_value = [option, value]
          for key in grammar.short_names + grammar.long_names
            @hash[key] = hash_value
          end
        else # Only happens if repeated?
          @hash[key].last << value
        end
      end
      if ast = ast.command
        @hash[ast.name] = [ast, OptionsHash.new(ast)]
      end
    end

    def key?(key) @hash.key?(key) end
    def [](key) @hash[key]&.last end
    def keys() @hash.keys end
    def values() end


    def default(key, default_value) key?(key) ? self[key] : default_value end

    def node(key, index = 0) end
    def user(key) end
    def count(key) Array(self[key]).size end
  end
end

