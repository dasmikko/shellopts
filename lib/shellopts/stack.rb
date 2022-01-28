module ShellOpts
  module Stack
    refine Array do
      def top() last end
    end
  end
end
