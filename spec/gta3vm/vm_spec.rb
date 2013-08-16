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
    it "should execute instruction from bytecode (more)" do
      bytecode = [
        [0x00, 0x00, 0x00, 0x00], # memory for variable 1
        [0x00, 0x00, 0x00, 0x00], # memory for variable 2
        [0x04, 0x00], [ [0x02,[0x00, 0x00]], [[0x01,[0x01, 0x00, 0x00, 0x00]]] ], # set mem 0x00 = 1

      ].to_byte_string 
      Gta3Vm::Vm.new(bytecode: bytecode).execute { |exe|
        exe.pc = 8 # HACK: skip past variables to start of code
        exe.tick
        exe.vm.memory.read(0,4).should == [0x01,0x00,0x00,0x00]
      }
    end



    decribe "Better execution" do
      it "should run" do
        vm = Gta3Vm::Vm.new(bytecode: load_bytecode(<<-BYTECODE))
          @0004  02 00 00  01 01 00 00 00 # SET_VAR_INT pg:0 int32:1
          @0008  02 00 00  01 04 00 00 00 # ADD_VAL_TO_INT_VAR pg:0 int32:4
        BYTECODE
        # pg:0 should eq 5
      end
    end
  end

  describe "opcodes" do
    describe "0004 SET_VAR_INT" do
      it "should work" do
        #             0004       pg 4            int32 8
        load_bytecode(0x04,0x00, 0x02,0x04,0x00, 0x01,0x08,0x00,0x00,0x00) do |vm|
          vm
        end
      end
    end
  end

  # set pg 0 to 1
  # if 0
  # if_pg_eq (pg 0) (int 1)
  # jump_if_false :nah
  # set pg 1 to 1
  # :nah

  describe "compilation" do
    it "should compile ruby into bytecode" do
      code = <<-RUBY
        $x00 = 0
        if $x00 == 1
          $x04 = 1
        end
      RUBY
    end
  end



  def load_bytecode(bytecode)
    yield = Gta3Vm::Vm.new(bytecode: (memory_bytecode() + bytecode)to_byte_string )
  end

  def memory_bytecode(memory = 128)
    end_of_block = 8 + memory # jump opcode + marker

  end

end