require "spec_helper"

describe Vm do 

  describe "disassembly" do

    it "should disassemble opcode" do
      opcode = vm_with_mem("04 00  02 0c 01  04 00").disassemble_opcode_at(0)
      opcode.should == [[4, 0], [[2, [12, 1]], [4, [0]]]]
    end

  end  


  describe "data types" do
    
    describe "disassemble_opcode_arg_at" do
      
    end

    describe "arg_to_native" do
      
    end

  end


  describe "variable arguments" do
    
  end


  describe "detect_scm_structures!" do
    
  end

end

def vm_with_mem(memory)
  memory = memory.gsub(/\s+/,'').scan(/(..)/).map{ |hex| hex[0].hex }
  memory = memory.to_byte_string if memory.is_a?(Array)
  Vm.new(memory)
end

class Vm
  alias_method :really_detect_scm_structures!, :detect_scm_structures!
  def detect_scm_structures!
  end
end
