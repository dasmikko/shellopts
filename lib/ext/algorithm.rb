
module Algorithm
  def follow(object, sym = nil, &block)
    sym.nil? == block_given? or raise "Can't use both symbol and block"
    a = []
    while object
      a << object
      object = block_given? ? yield(object) : object.send(sym)
    end
    a
  end

  module_function :follow
end
