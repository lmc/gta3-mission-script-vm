class Gta3Vm::Assembler < Gta3Vm::Disassembler

  def assemble
    @labels_to_offsets_sources = {}
    @labels_to_offsets_usages = {}
    @global_variables_ids = {}
    input.each_line.each_with_index do |line,line_no|
      assemble_line(line,line_no)
    end
    output.seek(0)
    insert_labels
    output.close
    puts "done\n\n"
    system("hexdump assembled.scm")
  end

  def assemble_line(line,line_no)
    puts "#{line_no.to_s.rjust(5,"0")}"
    tokens = line.split(" ")
    case tokens[0]
    when nil
    when /^\s*?$/
      # empty
    when /^#/
      puts "  comment"
    when /^:/
      puts "  label"
      label = tokens[0].gsub(/^(:)/,'')
      @labels_to_offsets_sources[ label ] = output.pos

    # TODO: write structure IDs
    when /^MEMORY/
      bytes = tokens[1].to_i
      puts "  MEMORY #{bytes}"
      output << "\x6d" # FIXME: hardcoded VC memory marker
      output << "\x00" * bytes
    when /^MODEL_COUNT/
      raise "derp" if tokens[1].to_i > 0
      output << "\x00" # model section id
      output << "\x00" * 4 # model count
    when /^MODEL/

    when /^MISSION_COUNT/
      raise "derp" if tokens[1].to_i > 0
      output << "\x00" # mission section id
      output << "\xff" * 4 # MAIN size
      output << "\xff" * 4 # largest mission size
      output << "\xff" * 4 # number of missions
    when /^MISSION/

    else
      puts "  instruction: #{tokens[0].inspect}"
      definition = vm.opcodes.definition_for_name( tokens[0] )
      if !definition
        raise "no instruction #{tokens[0].inspect}"
      else
        puts "  definition: #{definition.inspect}"
        puts "  #{vm.hex(definition.bytes)}"
        output << definition.bytes.map(&:chr).join

        tokens[1..-1].each_with_index do |token, token_idx|
          arg_type = definition.args_types[token_idx]
          puts "  arg #{token_idx} - #{token} - #{arg_type}"
          arg = assemble_arg(token)
          puts "    #{vm.hex(arg.bytes.to_a)}"
          output << arg
        end

        is_var_args = definition.args_names == [:var_args]
        if is_var_args
          puts "  is_var_args"
          puts "  00"
          output << "\x00"
        end

      end
    end
  end

  def assemble_arg(token)
    case token
    when /^\$:(\w+)$/
      puts "label #{$1} at #{output.pos + 1}"
      @labels_to_offsets_usages[$1] = output.pos + 1 # just after pg type
      "".tap do |arg|
        arg << vm.type_shorthand_to_int(:int32).chr
        arg << "\xFF\x80\x08\xFF"
      end
    when /^\$(\w+)$/ # global var
      value = observe_global_variable($1, output.pos + 1)
      arg_type = vm.type_shorthand_to_int(:int16)
      "".tap do |arg|
        arg << arg_type.chr
        arg << vm.native_to_arg_value(arg_type,value).map(&:chr).join
      end
    when /^((\+|\-)?\d+)$/ # integer
      value = $1.to_i
      # puts "    value: #{value.inspect}"
      "".tap do |arg|
        arg_type = vm.type_shorthand_to_int(:int32)
        arg << arg_type.chr
        arg << vm.native_to_arg_value(arg_type,value).map(&:chr).join
      end
    when /^s\"([^\"]+)\"$/ # string
      string = $1
      string = string[0...7].ljust(8,"\x00")
      string
    end
  end

  def observe_global_variable(name,offset)
    @global_variables_id ||= 0
    id = if @global_variables_ids.key?(name)
      @global_variables_ids[name]
    else
      @global_variables_id += 4
      @global_variables_ids[name] = @global_variables_id
      @global_variables_ids[name]
    end
    id
  end

  def insert_labels
    puts "@labels_to_offsets_sources"
    puts @labels_to_offsets_sources.inspect
    puts "@labels_to_offsets_usages"
    puts @labels_to_offsets_usages.inspect
    puts "@global_variables_ids"
    puts @global_variables_ids.inspect

    @labels_to_offsets_usages.each_pair do |label,usage_pos|
      source_pos = @labels_to_offsets_sources[label]
      payload = vm.native_to_arg_value( vm.type_shorthand_to_int(:int32), source_pos ).map(&:chr).join
      output.seek(usage_pos)
      output << payload
    end
  end

  protected

  def input
    File.open("disassemble-bootloader.txt","r")
  end

  def output
    @output ||= File.open("assembled.scm","w")
  end

end
