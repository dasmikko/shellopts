
include ShellOpts

describe "Lexer" do
  describe "#lex" do
    # Doesn't include the initial program token
    def make(src, fields: nil)
      fields = Array(fields).flatten
      tokens = ::ShellOpts::Lexer.new("rspec", src).lex[1..-1]
      tokens.pop while tokens.last&.kind == :blank
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

    it "accepts an empty source" do
      tokens = ::ShellOpts::Lexer.lex("rspec", "")[1..-1]
      expect(tokens).to be_empty
    end

    it "creates a program token as the first token" do
      src = %()
      tokens = ::ShellOpts::Lexer.lex("rspec", src)
      expect(tokens.map(&:kind)).to eq [:program]
    end

    it "creates options tokens" do
      src = %(
        -a,all
        --beta
        -c,config --data
      )
      expect(make src, fields: :kind).to eq [:option, :option, :option, :option]
      expect(make src, fields: :source).to eq %w(-a,all --beta -c,config --data)
    end

    it "creates command tokens" do
      src = %(
        !cmd
        !cmd.cmd2
      )
      expect(make src, fields: :kind).to eq [:command, :command]
      expect(make src, fields: :source).to eq %w(!cmd !cmd.cmd2)
    end

    it "creates spec and argument tokens" do
      src = %(
        -a ++ ARG1 ARG2
      )
      expect(make src, fields: :kind).to eq [:option, :spec, :argument, :argument]
      expect(make src, fields: :source).to eq %w(-a ++ ARG1 ARG2)
    end

    it "creates usage tokens" do
      src = "-- ARG1 ARG2"
      expect(make src, fields: :kind).to eq [:usage]
      expect(make src, fields: :source).to eq [src]
    end

    it "creates brief tokens" do
      src = "-c # Brief"
      expect(make src, fields: :kind).to eq [:option, :brief]
      expect(make src, fields: :source).to eq %w(-c Brief)
    end

    it "creates doc tokens" do
      src = %(
        -a
          Explanation
      )
      expect(make src, fields: :kind).to eq [:option, :doc]
      expect(make src, fields: :source).to eq %w(-a Explanation)
    end

    it "considers lines starting with \ as comments" do
      src = %(
        -o
        \\-p
      )
      expect(make src, fields: :kind).to eq [:option, :doc]
      expect(make src, fields: :source).to eq %w(-o -p)
    end
    it "creates blank-line token" do
      src = %(
        Hello

        -a
      )
      expect(make src, fields: :kind).to eq [:doc, :blank, :option]
    end

    it "ignores initial blank and commented lines" do
      src = %(
        
        -a
# Meta-comment
        Text
      )
      expect(make src, fields: :kind).to eq [:option, :doc]
    end
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

