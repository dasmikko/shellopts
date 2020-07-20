require "shellopts"

module ShellOpts
  class OptionsHash
    attr_reader :ast

    # @hash
    #   grammar.keys => [ast, value]
    #                => [[ast, value], ...]
    #                => [ast, OptionsHash]

    def initialize(ast)
      @ast = ast
      @hash = {} # Hash from Ast keys to [ast_node, option_value(s)] TODO: Should be [grammar_node, ...]
      for option in ast.options
        value = [option, option.grammar.argument? ? option.value : true]
        if !@hash.key?(option.name) # Only true first this option is processed
          value = [value] if option.grammar.repeated?
#         hash_value = [option, value] # Ensure only one instance for multiple keys
          option.grammar.names.each { |name| @hash[name] = value }
        else # Only happens if repeated?
          @hash[option.name] << value
        end
      end
      if command = ast.command
        @hash[command.name] = [command, OptionsHash.new(command)]
      end
    end

    def key?(key) @hash.key?(key) end

    def [](key) 
      entry = @hash[key] or return nil
      entry.first.is_a?(Array) ? entry.map(&:last) : entry.last
    end

    def size() keys.size end
    def keys() @ast.options.map(&:name) + [@ast.command&.name].compact end
    def values() 
      p keys
      keys.map { |key| self[key] } end

    def name(key, index = nil)
      p @hash.keys
      p keys
      p "------------------------------------------------------------"
      if index.nil?
        @hash[key].first.name
      else
        p @hash[key]
        p @hash[key].last[index]
        @hash[key].last[index].name
      end
    end

#   def name(key, index = 0) node(key, index)&.name end
#   def node(key, index = 0) @hash[key]&.first end


#   def default(key, default_value) key?(key) ? self[key] : default_value end

  private
    def value_of(key)
      entry = @hash[key] or return nil
      case entry.first
        when Ast::Node; entry.last
        when Array; entry.last
      else
        raise "Oops"
      end
    end

  end
end

