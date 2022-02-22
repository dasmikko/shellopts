include ShellOpts

describe "shellopts" do
  it 'has a version number' do
    expect(ShellOpts::VERSION).not_to be_nil
  end

  it 'does something useful'

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
