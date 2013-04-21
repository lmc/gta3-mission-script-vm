
# (load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc)

# vm = Gta3Vm::Vm.new(bytecode: "bytecode", game: "vc")

# VM
# MemorySpace # 
# [ByteCode]

load "lib/gta3vm/vm_vice_city.rb"
load "lib/gta3vm/logger.rb"
load "lib/gta3vm/memory.rb"
load "lib/gta3vm/opcodes.rb"

class Gta3Vm::Vm

  attr_accessor :memory
  attr_accessor :opcodes

  def initialize(options = {})
    options.reverse_merge!(
      bytecode: nil
    )

    self.memory = Gta3Vm::Memory.new(self,options[:bytecode])
    self.opcodes = Gta3Vm::Opcodes.new(self)
  end

  def opcode_at(offset)
    
  end


  # ####################

  def self.new_for_vc
    Gta3Vm::VmViceCity.new(bytecode: File.read("./main-vc.scm"))
  end

  def self.scm_markers
    raise "abstract"
  end

end
