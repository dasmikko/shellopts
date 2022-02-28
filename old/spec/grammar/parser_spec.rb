

#   describe "#initialize" do
#     it "checks that the name is not a reseved word" do
#       expect { Option.new %w(instance_eval) }.to raise_error CompileError, "Reserved word: instance_eval"
#       expect { Option.new %w(eval) }.not_to raise_error
#       expect { Option.new %w(eval instance_eval) }.not_to raise_error
#     end
#   end

