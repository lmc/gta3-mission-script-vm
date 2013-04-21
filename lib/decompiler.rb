class Decompiler
  attr_accessor :vm
  attr_accessor :stream
  attr_accessor :indent

  attr_accessor :variable_labels

  def initialize(vm)
    self.vm = vm
    self.stream = File.open('decompile.txt','w')
    self.indent = 0

    load_variable_labels!
  end

  def decompile!
    stream.puts "# disassembly of VM with data_dir = #{vm.data_dir.inspect}"
    stream.puts "# "
    stream.puts "# struct_positions: #{vm.struct_positions.inspect}"
    stream.puts "# "
    stream.puts "# models: #{vm.models.inspect}"
    stream.puts "# "
    stream.puts "# missions: #{vm.missions.inspect}"
    stream.puts "# "

    stream.puts ""
    stream.puts "# MAIN"

    offset = vm.struct_positions[:main][0]
    end_offset = vm.struct_positions[:main][1]

    while offset < end_offset
      opcode = vm.disassemble_opcode_at(offset)
      disassemble_opcode(offset,opcode)
      offset += opcode.flatten.size
    end


    stream.puts ""
    stream.puts "# MISSIONS"

    vm.missions.each_pair do |mission_id,offset|
      stream.puts ""
      stream.puts "# MISSION #{mission_id}"

      end_offset = vm.missions[mission_id - 1] || vm.struct_positions[:mission_code][1]

      while offset < end_offset
        opcode = vm.disassemble_opcode_at(offset)
        disassemble_opcode(offset,opcode)
        offset += opcode.flatten.size
      end
    end

    while offset < end_offset
      opcode = vm.disassemble_opcode_at(offset)
      disassemble_opcode(offset,opcode)
      offset += opcode.flatten.size
    end

    stream.close
  end

  def disassemble_opcode(offset,opcode)
    jump_sources = vm.opcode_addresses_to_jump_sources[offset]
    if jump_sources && jump_sources.size > 0
      emit_label(offset,jump_sources)
    end

    definition = vm.opcodes_module.definitions[opcode[0]]

    opcode_name = definition[:sym_name]
    args = opcode[1].each_with_index.map { |arg,index| format_arg(offset,opcode[0],opcode[1],index) }



    stream.puts "%s:%s (%s %s)" % [offset, ("  "*self.indent),opcode_name, args.join(" ")]


    if ["00D6"].include?(definition[:nice])
      self.indent += 1
    elsif ["004D"].include?(definition[:nice])
      self.indent -= 1
    end
  end

  def format_arg(offset,opcode,args,arg_id)
    arg = args[arg_id]

    arg_type = Vm::TYPE_SHORTHANDS_INV[arg[0]] || arg[0]
    arg_native = vm.arg_to_native(*arg)
    arg_value = arg_native.inspect

    if vm.opcodes_module.definitions[opcode][:args_names][arg_id] =~ /^jump_/
      arg_type = "label"
      if arg_native < 0 # negative jump offsets are relative jumps, used in missions
        mission = vm.get_mission_from_offset(offset)
        absolute_offset = mission[0].begin - arg_native
        arg_type = "label_mission"
        arg_value = "label_#{absolute_offset}"
      else
        arg_value = "label_#{arg_value}"
      end
    end

    if arg[0] == Vm::TYPE_SHORTHANDS[:pg]
      # puts vm.arg_to_native(*arg)
      if label = self.variable_labels[ vm.arg_to_native(*arg) ]
        arg_value = label
      end
    end

    "(%s %s)" % [ arg_type, arg_value ]
  end

  def emit_label(offset,jump_sources)
    source_labels = jump_sources.sort.map{|adr| "#{adr}(#{relative_offset(offset,adr)})" }
    stream.puts("\nlabel_#{offset}: (jumped to from: #{source_labels.join(', ')})")
  end

  def relative_offset(base_offset,offset)
    opcodes_difference = vm.opcode_map.index(offset) - vm.opcode_map.index(base_offset) rescue 0
    difference = offset - base_offset
    sign = difference > 0 ? "+" : "-"
    "#{sign}#{difference.abs}B #{sign}#{opcodes_difference.abs}L"
  end

  def load_variable_labels!
    self.variable_labels = {}
    File.open("./data/#{vm.data_dir}/CustomVariables.ini").each_line do |line|
      next if line =~ /^;/
      id, label = line.strip.split('=')
      id = id.to_i
      next unless id > 0
      self.variable_labels[ id * 4 ] = label
    end
    puts self.variable_labels.inspect
  end
end