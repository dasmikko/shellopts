include ShellOpts

describe "ShellOpts" do
  it 'has a version number' do
    expect(ShellOpts::VERSION).not_to be_nil
  end

# describe "::process" do
#   it "Returns a tuple of ShellOpts::Program and ShellOpts::Args objects" do
#     spec = "-a"
#     argv = %w(-a arg)
#     opts, args = ShellOpts::ShellOpts.process(spec, argv)
#     expect(opts.is_a?(ShellOpts::Program)).to eq true
#     expect(args).to be_a(ShellOpts::Args)
#   end
#   it "adds default --version and --help options is stdopts is true" do
#     spec = "-a"
#     opts, args = ShellOpts::ShellOpts.process(spec, [])
#     expect(ShellOpts.shellopts.grammar.options.map(&:ident)).to eq [:a, :version, :help]
#   end
# end
end

describe "ShellOpts::ShellOpts" do
  describe "find_spec_in_text" do
    def find(text, spec)
      oneline = spec.index("\n").nil?
      spec = spec.sub(/^\s*\n/, "")
      ShellOpts::ShellOpts.find_spec_in_text(text, spec, oneline)
    end

    it "returns [nil, nil] if not found" do
      spec = %(
        asdf
      )

      text = %(
        qwerty
      )
      expect(find(text, spec)).to eq [nil, nil]

      text = %(
        asdf
      )
      expect(find(text, spec)).not_to eq [nil, nil]
    end

    it "returns [line-index, char-index] of the spec with within text" do
      spec = %(
          -a,all      Option
          -b,beta     Opt
      )
      text = %(
        Some text
        SPEC = %(
          -a,all      Option
          -b,beta     Opt
        )
        Some more text
      )
      expect(find(text, spec)).to eq [3, 10]
    end

    it "ignores lines that could be interpreted by ruby" do
      interpolated = "interpolated text"
      spec = %(
          -a,all      #{interpolated}
          -b,beta
      )
      text = %(
          -a,all      \#{interpolated}
          -b,beta
      )
      expect(find(text, spec)).to eq [1,10]
    end
  end
end
