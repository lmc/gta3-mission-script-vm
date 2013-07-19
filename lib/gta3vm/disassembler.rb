# (($: << "./lib") && load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc.disassemble && exit)

class Gta3Vm::Disassembler
  attr_accessor :vm
  attr_accessor :out

  attr_accessor :offsets_to_instructions
  attr_accessor :observed_jumps

  def initialize(vm)
    self.vm = vm
  end

  def disassemble
    self.out = File.open('disassemble.txt','w')  
    self.offsets_to_instructions = Hash.new { |h,k| h[k] = [] }
    self.observed_jumps = []
    begin
      disassemble_structure
      disassemble_code
    ensure
      output_disassembly
      self.out.close
    end
  end

  OPCODES_WITH_JUMPS = {
    [0x02,0x00] => 0,
    [0x4C,0x00] => 0,
    [0x4F,0x00] => 0,
    [0x50,0x00] => 0,
  }
  def get_jumps_for_instruction(instruction)
    OPCODES_WITH_JUMPS[instruction.opcode]
  end

  protected

  def output_disassembly
    self.offsets_to_instructions.keys.sort.each do |offset|
      if observed_jumps.include?(offset)
        self.out.puts ""
        self.out.puts ":#{offset}"
      end
      self.offsets_to_instructions[offset].each do |declaration|
        self.out.puts declaration     
      end
    end
  end

  def disassemble_structure
    offset = 0
    offset += disassemble_instruction_at(offset).size
    emit_declare(offset, :MEMORY, vm.memory.global_memory_size)

    offset = vm.memory.structure[:memory].end
    offset += disassemble_instruction_at(offset).size
    vm.memory.structure_models.each_with_index do |model,idx|
      emit_declare(offset, :MODEL, idx,model)
    end

    offset = vm.memory.structure[:models].end
    offset += disassemble_instruction_at(offset).size
    vm.memory.structure_missions.each_with_index do |mission_offset,idx|
      emit_declare(offset, :MISSION, idx,mission_offset)
    end
  end

  def disassemble_code
    offset = vm.memory.structure[:code_main].begin
    while offset < vm.memory.structure[:code_main].end
      offset += disassemble_instruction_at(offset).size
    end
  end

  def disassemble_instruction_at(offset)
    instruction = vm.instruction_at(offset)
    emit_instruction(offset,instruction)
    instruction
  end

  def emit_declare(offset,tag,*values)
    self.offsets_to_instructions[offset] << "#{tag} #{values.join(', ')}"
  end

  def emit_instruction(offset,instruction)
    definition = vm.opcodes.definition_for( instruction.opcode )
    native_args = instruction.to_ruby(vm)[1]
    args = native_args.each_with_index.map{|arg,i| emit_arg( instruction.args[i][0], arg[1] ) }
    if arg_pos = get_jumps_for_instruction(instruction)
      self.observed_jumps << native_args.values[arg_pos]
    end
    emit_declare(offset,definition.symbol_name,*args)
  end

  def emit_arg(type,value)
    case vm.type_int_to_shorthand(type)
    when :pg
      "$#{value}"
    when :pl
      "@#{value}"
    else
      value
    end
  end

end
