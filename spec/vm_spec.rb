# require "spec_helper"

# describe Vm do 

#   describe "disassembly" do

#     it "should disassemble opcode" do
#       disassemble_opcode("04 00  02 0c 01  04 00").should == [[4, 0], [[2, [12, 1]], [4, [0]]]]
#     end

#   end  


#   describe "data types" do
    
#     describe "disassemble_opcode_arg_at" do
#       it "should disassemble int32s" do
#         disassemble_arg("01 20 86 00 00").should == [1, [32, 134, 0, 0]]
#       end
#       it "should disassemble pgs" do
#         disassemble_arg("02 20 86").should == [2, [32, 134]]
#       end
#       it "should disassemble int8s" do
#         disassemble_arg("04 fe").should == [4, [254]]
#       end
#       it "should disassemble int16s" do
#         disassemble_arg("05 20 40").should == [5, [32, 64]]
#       end
#       it "should disassemble float32s" do
#         disassemble_arg("06 fe b5 70 00").should == [6, [254, 181, 112, 0]]        
#       end
#       it "should disassemble immediate 8-byte strings" do
#         disassemble_arg("09 90 90 90 90 91 91 91 91").should == [9, [144, 144, 144, 144, 145, 145, 145, 145]]
#       end
#       it "should disassemble variable-length strings" do
#         disassemble_arg("0e 02 01 02").should == [14, [2, 1, 2]]
#         disassemble_arg("0e 04 01 02 03 04").should == [14, [4, 1, 2, 3, 4]]
#       end
#       it "should disassemble type-less immediate 8-byte strings" do
#         disassemble_arg("91 92 93 94 95 96 97 98").should == [145, [146, 147, 148, 149, 150, 151, 152]]
#       end
#     end

#     describe "arg_to_native" do
      
#     end

#   end


#   describe "variable arguments" do
#     it "should disassemble opcodes with a variable number of args" do
#       disassemble_opcode("4f 00 01 01 02 03 04 04 ff 02 ee ee 00").should == [
#         [79, 0], [[1, [1, 2, 3, 4]], [4, [255]], [2, [238, 238]], [0]]
#       ]
#     end
#   end


#   describe "detect_scm_structures!" do
    
#   end

# end

# def disassemble_opcode(memory)
#   vm_with_mem(memory).disassemble_opcode_at(0)
# end

# def disassemble_arg(memory)
#   vm_with_mem(memory).disassemble_opcode_arg_at(0)
# end

# def vm_with_mem(memory)
#   memory = memory.gsub(/\s+/,'').scan(/(..)/).map{ |hex| hex[0].hex }
#   memory = memory.to_byte_string if memory.is_a?(Array)
#   Vm.new(memory)
# end

# class Vm
#   alias_method :really_detect_scm_structures!, :detect_scm_structures!
#   def detect_scm_structures!
#   end
# end
