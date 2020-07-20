require "shellopts"

module ShellOpts
  class OptionsHash
    def initialize(ast)
      @ast = ast

      @value_by_name = {} # Map from name and synonymons to value or list of values
      @value_by_key = {}  # Map from key to value or list of values
      @nodes_by_name = {} # Map from name and synonymons to list of nodes

      for option in ast.options
        value = option.grammar.argument? ? option.value : true
        if !@value_by_name.key?(option.name) # Only true first this option is processed
          value = [value] if option.grammar.repeated?
          nodes = [option] # 'nodes' is needed to avoid duplicate instances because of [...]
          for name in option.grammar.names + [option.grammar.key]
            @value_by_name[name] = value
            @nodes_by_name[name] = nodes
          end
          @value_by_key[option.key] = value
        else # Only happens if repeated option
          @value_by_name[option.key] << value
          @nodes_by_name[option.key] << option
        end
      end
      if ast = ast.command
        @value_by_name[ast.name] = @value_by_key[ast.key] = OptionsHash.new(ast)
        @nodes_by_name[ast.name] = [ast]
      end
    end

    def key?(name) @value_by_name.key?(name) end
    def [](name) @value_by_name[name] end

    def size() @value_by_key.size end
    def keys() @value_by_key.keys end
    def values() @value_by_key.values end

    def name(name, index = 0) node(name, index)&.name end
    def node(name, index = 0) @nodes_by_name[name]&.[](index) end
    def count(name) Array(@value_by_name[name] || []).size end

    def default(key, default_value) key?(key) ? self[key] || default_value : nil end
  end
end

