# (($: << "./lib") && load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc.disassemble && exit)

class Gta3Vm::Disassembler
  attr_accessor :vm
  attr_accessor :out

  attr_accessor :offsets_to_instructions
  attr_accessor :observed_jumps
  attr_accessor :observed_thread_names


  def initialize(vm)
    self.vm = vm
  end

  def disassemble
    self.out = File.open('disassemble.txt','w')  
    self.offsets_to_instructions = Hash.new { |h,k| h[k] = [] }
    self.observed_jumps = []
    self.observed_thread_names = {}
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
    [0x4D,0x00] => 0,
    [0x4F,0x00] => 0,
    [0x50,0x00] => 0,
    [0xD7,0x00] => 0,
  }
  def get_jumps_for_instruction(instruction)
    OPCODES_WITH_JUMPS[instruction.opcode]
  end

  protected

  def output_disassembly
    self.offsets_to_instructions.keys.sort.each do |offset|
      if vm.memory.structure_missions.include?(offset)
        self.out.puts ""
        self.out.puts ""
        self.out.puts ""
      end
      if observed_jumps.include?(offset)
        self.out.puts ""
        self.out.puts ":#{emit_label_name(offset,offset)}"
      end
      self.offsets_to_instructions[offset].each do |declaration|
        self.out.puts declaration     
      end
    end
  end

  def offset_has_label?(offset)
    @observed_jumps_sorted ||= self.observed_jumps.sort
    @observed_jumps_sorted.binary_index(offset) != nil
  end

  def disassemble_structure
    offset = 0
    offset += disassemble_instruction_at(offset).size
    emit_declare(offset, :MEMORY, vm.memory.global_memory_size)
    # ast_emit_declare_memory(offset,vm.memory.global_memory_size)

    offset = vm.memory.structure[:memory].end
    offset += disassemble_instruction_at(offset).size
    vm.memory.structure_models.each_with_index do |model,idx|
      emit_declare(offset, :MODEL, idx,model)
      # ast_emit_declare_model(offset,idx,model)
    end

    offset = vm.memory.structure[:models].end
    offset += disassemble_instruction_at(offset).size
    vm.memory.structure_missions.each_with_index do |mission_offset,idx|
      self.observed_jumps << mission_offset
      emit_declare(offset, :MISSION, idx,"$:#{emit_label_name(mission_offset,mission_offset)}")
      # ast_emit_declare_mission(offset,idx,mission_offset)
    end
  end

  def disassemble_code
    offset = vm.memory.structure[:code_main].begin
    end_offset = vm.memory.structure[:code_missions].try(:end) || vm.memory.structure[:code_main].end
    # end_offset = vm.memory.structure[:code_main].end
    while offset < end_offset
      offset += disassemble_instruction_at(offset).size
    end
  end

  def disassemble_instruction_at(offset)
    instruction = vm.instruction_at(offset)
    emit_instruction(offset,instruction)
    # ast_emit_instruction(offset,instruction)
    instruction
  end

  def emit_label_name(offset,instruction_offset)
    # mission_id = get_mission_id_for_offset( offset < 0 ? instruction_offset : offset)
    mission_id = nil
    if offset < 0
      mission_id = get_mission_id_for_offset(instruction_offset)
    elsif vm.memory.structure_missions[0] && offset >= vm.memory.structure_missions[0]
      mission_id = get_mission_id_for_offset(offset)
    end

    if mission_id
      "mission_#{mission_id}_#{get_abs_offset(offset,instruction_offset)}"
    else
      # thread_name = get_thread_name_for_offset(offset) || "main"
      thread_name = "main"
      "#{thread_name}_#{offset}"
    end
  end

  def get_mission_id_for_offset(offset)
    @get_mission_id_for_offset ||= {}
    if @get_mission_id_for_offset.key?(offset)
      @get_mission_id_for_offset[offset]
    else
      @get_mission_id_for_offset[offset] = _get_mission_id_for_offset(offset)
      @get_mission_id_for_offset[offset]
    end
  end

  def _get_mission_id_for_offset(offset)
    if vm.memory.structure_missions[0] && offset >= vm.memory.structure_missions[0]
      (vm.memory.structure_missions + [Float::INFINITY]).each_with_index do |mission_offset,id|
        if offset < mission_offset 
          return id - 1
        end
      end
    end
    nil
  end

  def get_thread_name_for_offset(offset)
    @get_thread_name_for_offset ||= {}
    if @get_thread_name_for_offset.key?(offset)
      @get_thread_name_for_offset[offset]
    else
      @get_thread_name_for_offset[offset] = _get_thread_name_for_offset(offset)
      @get_thread_name_for_offset[offset]
    end
  end

  def _get_thread_name_for_offset(offset)
    sorted_keys = self.observed_thread_names.keys.sort
    sorted_keys.each_with_index do |thread_offset,key_idx|
      if offset <= thread_offset
        key = self.observed_thread_names[ sorted_keys[key_idx - 1] ]
        puts "offset: #{offset} = #{key.inspect}"
        return key
        # puts "#{offset} < #{thread_offset}"
        # puts "key: #{key} - #{self.observed_thread_names[key].inspect}"
        # return self.observed_thread_names[key]
      end
    end
    nil
  end

  def get_abs_offset(offset,instruction_offset)
    if offset < 0
      mission_id = get_mission_id_for_offset(instruction_offset)
      offset = vm.memory.structure_missions[mission_id] + offset.abs
    end
    offset
  end


  def opcode_definition(instruction)
    vm.opcodes.definition_for(instruction.opcode)
  end



  def emit_declare(offset,tag,*values)
    self.offsets_to_instructions[offset] << "#{tag} #{values.join(', ')}"
  end

  def emit_instruction(offset,instruction)
    definition = vm.opcodes.definition_for( instruction.opcode )
    native_args = instruction.to_ruby(vm)[1]
    args = native_args.each_with_index.map{|arg,i| emit_arg( offset, instruction, i, instruction.args[i][0], arg[1] ) }

    if arg_pos = get_jumps_for_instruction(instruction)
      self.observed_jumps << get_abs_offset(native_args.values[arg_pos],offset)
    end

    if instruction.opcode == [0xA4,0x03] # SCRIPT_NAME
      name = native_args.values[0]
      self.observed_thread_names[offset] = name
    end

    emit_declare(offset,definition.symbol_name,*args)
  end

  def emit_arg(instruction_offset,instruction,arg_idx,type,value)
    if arg_idx == get_jumps_for_instruction(instruction)
      if value < 0
        "@:#{emit_label_name(value,instruction_offset)}"
      else
        "$:#{emit_label_name(value,instruction_offset)}"
      end
    else
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


end
