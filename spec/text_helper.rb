
def undent(s)
  lines = s.split(/\s*\n/)
  lines.shift while !lines.empty? && !(lines.first =~ /^(\s*)(\S.*)$/)
  return "" if lines.empty?
  indent = $1.size
  r = []
  while line = lines.shift
    r << (line[indent..-1] || "")
  end
  while !r.empty? && r.last =~ /^\s*$/
    r.pop
  end
  r.join("\n") + "\n"
end

