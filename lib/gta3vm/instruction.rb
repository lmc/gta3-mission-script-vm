class NestedByteArray < Array

  def size
    flatten.length
  end

end

class Gta3Vm::Instruction < NestedByteArray

  def initialize(*args)
    super(*args)
    self[0] = [] unless self[0]
    self[1] = [] unless self[1]
  end

  def opcode
    self[0]
  end

  def opcode=(value)
    self[0] = Opcode.new(value)
  end

  def args
    self[1]
  end

  def args=(value)
    self[1] = Args.new(value)
  end

  def negated?
    
  end

  def negated_opcode
    
  end

  def to_ruby(vm)
    definition = vm.opcodes.definition_for(self.opcode)
    [
      definition.sym_name.to_sym,
      Hash[ definition.args_names.each_with_index.map do |arg_name,idx|
        [arg_name.to_sym, vm.arg_to_native(self.args[idx]) ]
      end ]
    ]
  end

  def arg_start_offsets
    offset = 2 # opcode is 2 bytes, args start after
    offsets = []
    self.args.each do |arg|
      offsets << offset
      offset += arg.size
    end
    offsets
  end



  class Gta3Vm::Instruction::Opcode < NestedByteArray

  end


  class Gta3Vm::Instruction::Args < NestedByteArray

  end


  class Gta3Vm::Instruction::Arg < NestedByteArray

    def type
      self[0]
    end

    def value
      self[1]
    end

  end

end

