
include ShellOpts

describe "Lexer" do
  describe "#lex" do
    # Doesn't include the initial program token
    def make(src, fields: nil)
      fields = Array(fields).flatten
      tokens = ::ShellOpts::Lexer.new(src).lex[1..-1]
      if fields
        if fields.size == 1
          tokens.map { |token| token.send(fields.first) }
        else
          tokens.map { |token|
            fields.map { |field| token.send(field) }
          }
        end
      else
        tokens
      end
    end

    it "accepts an empty source"

    it "creates a program token as the first token" do
      src = %()
      tokens = ::ShellOpts::Lexer.lex(src)
      expect(tokens.map(&:kind)).to eq [:program]
    end


    it "creates options tokens" do
      src = %(
        -a,all
        --beta
        -c,config --data
      )
      expect(make src, fields: :source).to eq %w(-a,all --beta -c,config --data)
      expect(make src, fields: :kind).to eq [:option, :option, :option, :option]
    end

    it "creates command tokens" do
      src = %(
        cmd!
        cmd.cmd2!
      )
      expect(make src, fields: :source).to eq %w(cmd! cmd.cmd2!)
      expect(make src, fields: :kind).to eq [:command, :command]
    end

    it "creates arguments tokens" do
      src = "-- ARG1 ARG2"
      p make(src)
      expect(make src, fields: :source).to eq [src]
      expect(make src, fields: :kind).to eq [:arguments]

    end

    it "creates sub-command arguments tokens"
    it "creates brief-comment tokens"
    it "creates comment tokens"
    it "considers lines starting with \ as comments" do
      src = %(
        -o
        \\-p
      )
      expect(make src, fields: :kind).to eq [:option, :line]
    end
    it "creates blank-line token"
    it "ignores blank lines except between comments" do
      src = %(
        Hello

        -a

        -b
        Hello

        World

        -c

      )
      expect(make src, fields: :kind).to eq \
          [:line, :option, :option, :line, :blank, :line, :option]
    end

    it "ignores initial blank and commented lines"
  end
end

__END__
SOURCE = %(
  -a,all      
  -b,beta # Brief inline comment     
  --verbose -h,help -v,version # Multi option line  
  -f=FILE   
    Indented comment  
# A comment that should not be included in the source (usefull to out-comment
# sections of source)
#
# The following blank line should be ignored       

  -l=MODE:short,long?   
    Another indented comment. The following blank line should be included

    But not if it is the last blank line     

  -- ARG1 ARG2   
  command!   
    Description of command. Then we list the options: 

      -c,copt # Inline comment  
      -d,dopt # Brief and nested comment  
        Even more nested comment   

    This text should be included too  
    ++ CMD_ARG1 CMD_ARG2 # Comment        
)

