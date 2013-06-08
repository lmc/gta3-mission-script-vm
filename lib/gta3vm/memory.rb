class Gta3Vm::Memory < String
  include Gta3Vm::Logger

  attr_accessor :vm
  attr_accessor :structure
  attr_accessor :opcode_map

  def initialize(vm,*args)
    self.vm = vm
    super(*args)
    self.force_encoding("ASCII-8BIT")
  end

  # assume it's a structured SCM if it starts with:
  # a jump (02 00), then a uint32 arg (01 xx xx xx xx), then a structure marker (xx), then 4 nulls
  def has_structure?
    self[0..2] == [0x02,0x00,0x01] && self[8..11] == [0x00,0x00,0x00,0x00]
  end

  def detect_structure
    log "detect_structure"
    self.structure = {}
    offset = 0
    markers = vm.class.scm_markers

    markers.each_with_index do |(marker,section_name),index|
      log "detect_structure: searching for #{section_name}"

      jump_instruction = vm.instruction_at(offset)
      log jump_instruction.inspect
      marker_at = offset + jump_instruction.size
      marker_value = vm.memory.read(marker_at,1)
      if marker_value != [marker]
        raise InvalidScmStructure, "Didn't find '#{section_name}' structure marker '#{marker}' at #{marker_at} (got #{marker_value})"
      end
      section_start = marker_at + 1

      offset = vm.arg_to_native(jump_instruction.args[0])
      jump_instruction = vm.instruction_at(offset)
      if jump_instruction.opcode != [0x02,0x00] && index != markers.size - 1
        raise InvalidScmStructure, "Didn't find jump after '#{struct_name}' structure at #{offset}"
      end
      log jump_instruction.inspect
      section_end = offset

      self.structure[section_name] = Range.new(section_start,section_end)
      log "detect_structure: found #{section_name} at #{self.structure[section_name].inspect}"
    end

    # TODO: do this properly, mark start of code_main and code_missions
    self.structure[:code_main] = Range.new( self.structure[:missions].end, self.size )

    log "structure: #{self.structure.inspect}"
    build_opcode_map
  end

  def build_opcode_map
    # For disassembly purposes, we need to know where an opcode begins
    # ignoring the special structures at the start of the SCM (memory, object table, mission table, etc.)
    # starting from the first opcode, record it's start address, fast-forward through the size of it's args to find the next opcode, repeat
    # will need to know arg counts for all opcodes, and size of all datatypes, with special handling for var_args
    puts "building disassembly map"
    self.opcode_map = []
    address = self.structure[:code_main].begin

      while address < self.size
        opcode_address = address
        instruction = vm.instruction_at(address)
        next_opcode_address = address + instruction.size
        address = next_opcode_address
        #puts "#{address.to_s.rjust(8,"0")} - #{ch(OPCODE,opcode[0].reverse)}: #{opcode[1].map{|arg| "#{ch(TYPE,arg[0])} #{arg[1] ? ch(VALUE,arg[1]) : ""}" }.join(', ')}"
        #puts dump_memory_at(address+opcode.flatten.size)
        self.opcode_map << opcode_address
      end

    # puts self.opcode_map.inspect
  end

  def read(offset,bytes = 1)
    self[(offset)...(offset+bytes)]
  end

  def write(address,bytes,byte_array)
    log "write: #{address} = #{bytes}@#{byte_array.inspect}"
    memory_range = (address)...(address+bytes)
    self[memory_range] = byte_array[0...bytes]
  end

  # #############

  def inspect
    "#<Gta3Vm::Memory bytes: #{self.bytesize}>"
  end

  # Make string act like an array of bytes
  alias_method :"old_read", :"[]"
  def [](args = nil)
    ret = super
    ret ? ret.bytes.to_a : nil
  end

  def raw_read(*args)
    old_read(*args)
  end

  def []=(pos,args)
    args = args.to_byte_string if args.is_a?(Array) && args[0].is_a?(Numeric)
    super(pos,args)
  end

end
