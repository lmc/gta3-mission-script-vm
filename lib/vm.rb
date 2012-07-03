OPCODE_ARG_COUNTS = {
  [0x02,0x00] => 1
}

class Vm
  attr_accessor :memory # ""

  attr_accessor :pc # 0
  attr_accessor :stack # []

  def self.load_scm(scm = "main")
    new( File.read("#{`pwd`.strip}/#{scm}.scm") )
  end

  def initialize(script_binary)
    self.memory = script_binary.bytes.to_a
    self.pc = 0
    self.stack = []

    tick!
  end

  def dump_memory_at(address,size = 16)
    start_offset = address
    end_offset = address + size
    puts "#{address} - #{hex self.memory[start_offset..end_offset]}"
  end

  def hex(array_of_bytes)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") }.join(" ")
  end

  def tick!
    dump_memory_at(pc)

    opcode = read(2)
    args = []

    OPCODE_ARG_COUNTS[opcode].times do
      arg_type = read(1)[0]
      arg = [arg_type]
      case arg_type
      when 1 # immediate 32 bit signed int 
        arg << read(4)
      end
      args << arg
    end

    puts "  opcode #{hex(opcode)} args: #{args.inspect}"

  end

  def inspect
    "pc: #{pc}"
  end

  protected

  def read(bytes = 1)
    read = self.memory[(self.pc)...(self.pc+bytes)]
    self.pc += bytes
    read
  end
end

# 0 - 02 00 01 20 ab 00 00 73 00 00 00 00 00 00 00 00 00
#   opcode 02 00 args: [[1, [32, 171, 0, 0]]]

