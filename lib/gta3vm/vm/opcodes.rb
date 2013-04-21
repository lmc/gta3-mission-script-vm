class Gta3Vm::Opcodes

  attr_accessor :vm
  attr_accessor :opcode_data

  def initialize(vm)
    self.vm = vm
    self.opcode_data = {}
    load_opcode_definitions
  end

  def load_opcode_definitions
    
  end


end
