module Opcodes
  def opcode_0002(jump_location)
    raise ArgumentError unless jump_location[0] == 0x01
    offset = jump_location[1].to_byte_string.unpack("l<")[0]
    puts "found jump to #{offset}?"
    dump_memory_at(offset)
    self.pc = offset
  end
end