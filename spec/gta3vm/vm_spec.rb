require 'spec_helper'

describe Gta3Vm::Vm do
  
  it "should initialize on a game-specific sub-class" do
    Gta3Vm::Vm.new_for_vc
  end

  describe "instruction_at" do
    it "should return Instruction with opcode and args" do
      bytecode = [[2, 0], [[1, [228, 154, 0, 0]]]].to_byte_string
      instruction = Gta3Vm::Vm.new(bytecode: bytecode).instruction_at(0)

      instruction.should be_a Gta3Vm::Instruction

      instruction.opcode.should be_a Gta3Vm::Instruction::Opcode
      instruction.opcode.should == [0x02,0x00]
      
      instruction.args[0].should be_a Gta3Vm::Instruction::Arg
      instruction.args[0].should == [0x01, [228, 154, 0, 0]]
    end
  end

  describe "execution" do
    it "should execute instruction from bytecode" do
      # jump 39652
      bytecode = [[2, 0], [[1, [228, 154, 0, 0]]]].to_byte_string 
      Gta3Vm::Vm.new(bytecode: bytecode).execute { |exe|
        exe.tick
        exe.pc.should == 39652
      }
    end
  end

end