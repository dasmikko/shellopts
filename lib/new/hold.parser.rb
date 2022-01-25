
module ShellOpts
  module Grammar
    class Node
      def parse
        ;
      end

      def self.parse(parent, token)
        this = self.new(parent, token)
        this.parse
        this
      end
    end

    class Option < Node
      def parse
        token.source =~ /^(-|--|\+|\+\+)([a-zA-Z0-9][a-zA-Z0-9_,-]*)(?:=(.+?)(\?)?)?$/ or 
            raise ParserError, "Illegal option: #{token.source.inspect}"
        initial = $1
        names = $2
        arg = $3
        optional = $4

        @repeatable = %w(+ ++).include?(initial)

        names = names.split(",").map { |name| name.sub("-", "_") }
        @short_names = []
        if %(- +).include?(initial)
          while names.first&.size == 1
            @short_names << names.shift
          end
        end
        @long_names = names
        @name = @long_names.first || @short_names.first
        @ident = ::ShellOpts::Expr::Command::RESERVED_OPTION_NAMES.include?(name) ? nil : name.to_sym
        @argument = !arg.nil?

        named = true
        if @argument
          if arg =~ /^([^:]+)(?::(.*))/
            @argument_name = $1
            named = true
            arg = $2
          elsif arg =~ /^:(.*)/
            arg = $1
            named = false
          end

          case arg
            when "", nil
              @argument_name ||= "VAL"
              @argument_type = ArgumentType.new
            when "#"
              @argument_name ||= "INT"
              @argument_type = IntegerArgument.new
            when "$"
              @argument_name ||= "NUM"
              @argument_type = FloatArgument.new
            when "FILE", "DIR", "NODE", "FILEPATH", "DIRPATH", "PATH", "NEW"
              @argument_name ||= %w(FILE DIR).include?(arg) ? arg : "PATH"
              @argument_type = FileArgument.new(@argument_name.downcase.to_sym)
            when /,/
              @argument_name ||= arg
              @argument_type = EnumArgument.new(arg.split(","))
            else
              named && @argument_name.nil? or raise ParserError, "Illegal type expression: #{arg.inspect}"
              @argument_name = arg
              @argument_type = ArgumentType.new
          end
          @optional = !optional.nil?
        else
          @argument_type = ArgumentType.new
        end
      end
    end

    class Command < Node
      def parse
        @path = token.to_s.sub("!", "")
        @name = @path.split(".").last
      end
    end

    class Program < Command
#     def self.parse(token)
#       super(nil, token)
#     end
    end

    class Spec < Node
      def parse # TODO
        super
      end
    end
  end

  class Parser
    include Grammar
    using Stack
    using Ext::Array::ShiftWhile

    # Array of token
    attr_reader :tokens

    # AST root node
    attr_reader :program

    def initialize(tokens)
      @tokens = tokens.dup
      @nodes = [] # Stack of Nodes. Follows the indentation of the source
    end

    def parse
      @program = Program.parse(nil, tokens.shift)
      stack = [program]
      indent = 0

      while token = tokens.shift
        # Unwind indentation
        while !stack.empty? && token.char < indent 
          stack.pop
          indent = stack.top.token.char
        end
        !stack.empty? or err(token, "Illegal indent")

        puts
        puts "token: #{token.inspect}"
        puts "stack.top.class: #{stack.top.class}"
        puts "stack.top.token: #{stack.top&.token.inspect}"

        # Handle text and find node class
        if token.kind == :text
          if stack.top.is_a?(Paragraph) && token.char == stack.top.token.char
            node = Text.new(stack.top, token)
            next
          end
          tokens.unshift token
          klass = stack.top.is_a?(Paragraph) ? Code : Paragraph
        elsif token.kind == :option && !stack.top.is_a?(OptionGroup)
          tokens.unshift token
          klass = OptionGroup
        else
          klass = eval(token.kind.to_s.capitalize)
        end

#       p stack.top.class

        # Find parent
        parent = stack.reverse.find { |node| allowed_child?(node, klass) }
        next if !parent && klass == Blank
        raise Error, "Can't find a parent for #{klass}" if !parent

        # Create node
        node = klass.parse(parent, token)

        # Push if a container node
        puts
        puts "klass: #{klass}"
        puts "node.class: #{node.class}"
        puts "has_children: #{HAS_CHILDREN[klass]}"
        stack.push node if HAS_CHILDREN[klass]
      end
      @program
    end

    def self.parse(tokens)
      self.new(tokens).parse
    end

  protected
    PARENTS = {
      Program => [], Command => [Program, Command],
      OptionGroup => [Program, Command], Option => [OptionGroup],
      Spec => [Program, Command], Argument => [Spec], Usage => [Program, Command],
      Brief => [Program, Command, OptionGroup, Spec, Usage],
      Paragraph => [Program, Command, OptionGroup], Code => [Program, Command, OptionGroup], 
      Text => [Paragraph, Code], Blank => [Code]
    }

    HAS_CHILDREN = PARENTS.values.flatten.inject({}) { |a,e| a[e] = true; a }

    def allowed_child?(node, klass)
      
      r = Parser::PARENTS[klass].any? { |k| node.is_a?(k) }
#     puts "allowed_child?(#{node.class}, #{klass}) -> #{r}"
      r
    end

    def err(token, message) raise ParserError, "#{token.pos} #{message}" end
  end
end

