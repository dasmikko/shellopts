def capture(&block)
  save = $stdout
  begin
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = save
  end
end


