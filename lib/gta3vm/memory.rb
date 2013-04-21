class Gta3Vm::Memory < String
  include Gta3Vm::Logger

  attr_accessor :vm
  attr_accessor :structure

  def initialize(vm,*args)
    self.vm = vm
    super(*args)
    self.force_encoding("ASCII-8BIT")

    detect_structure if has_structure?
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
    markers = vm.scm_markers

    markers.each_with_index do |(marker,section_name),index|

      jump_opcode = vm.opcode_at(offset)
      marker_at = offset + jump_opcode.size
      marker_value = vm.memory.read(marker_at,1)
      if marker_value != [marker]
        raise InvalidScmStructure, "Didn't find '#{section_name}' structure marker '#{marker}' at #{marker_at} (got #{marker_value})"
      end
      section_start = marker_at + 1

      offset = vm.arg_to_native(jump_opcode.args[0])
      jump_opcode = vm.opcode_at(offset)
      if jump_opcode.opcode != [0x02,0x00] && index != markers.size - 1
        raise InvalidScmStructure, "Didn't find jump after '#{struct_name}' structure at #{offset}"
      end
      section_end = offset

      self.structure[struct_name] = Range.new(section_start,section_end)
    end
  end

  # #############

  def inspect
    "#<Gta3Vm::Memory bytes: #{self.bytesize}>"
  end

  # Make string act like an array of bytes
  alias_method :"old_read", :"[]"
  def [](args = nil)
    super.bytes.to_a
  end

  def raw_read(*args)
    old_read(*args)
  end

  def []=(pos,args)
    args = args.to_byte_string if args.is_a?(Array) && args[0].is_a?(Numeric)
    super(pos,args)
  end

end
