require "shellopts/shellopts.rb"

module ShellOpts
  class OptionsHash
    attr_reader :ast

    def initialize(ast)
      @ast = ast

      @value_by_name = {} # Map from name and synonymons to value or list of values
      @value_by_key = {}  # Map from key to value or list of values
      @nodes_by_name = {} # Map from name and synonymons to list of nodes
      @command = nil      # Command key

      for option in ast.options
        value = option.grammar.argument? ? option.value : true
        if !@value_by_name.key?(option.name) # Only true the first this option is processed
          value = [value] if option.grammar.repeated? # Also avoids duplicate instances
          nodes = [option] # 'nodes' is needed to avoid duplicate instances
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
        @nodes_by_name[ast.name] = @nodes_by_name[ast.key] = [ast]
        @command = ast.key
      end
    end

    def key?(name) @value_by_name.key?(name) end
    def [](name) @value_by_name[name] end

    def size() @value_by_key.size end
    def keys() @value_by_key.keys end
    def values() @value_by_key.values end

    def each(&block) @value_by_key.each(&block) end

    def name(name = nil, index = nil) 
      !name.nil? || index.nil? or raise InternalError, "Illegal combination of arguments"
      name ? node(name, index)&.name : ast.name
    end

    def node(name = nil, index = nil)
      !name.nil? || index.nil? or raise InternalError, "Illegal combination of arguments"
      name ? Array(@nodes_by_name[name])[index || 0] : ast
    end

    def count(name) Array(@value_by_name[name] || []).size end

    def command() @command end

    def default(key, default_value) key?(key) ? self[key] || default_value : nil end
  end
end

