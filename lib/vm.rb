load "lib/opcodes.rb"

OPCODE_ARG_COUNTS = {
  [0x02,0x00] => 1
}

class Vm
  attr_accessor :memory # ""

  attr_accessor :pc # 0
  attr_accessor :stack # []

  attr_accessor :opcode
  attr_accessor :args

  def self.load_scm(scm = "main")
    new( File.read("#{`pwd`.strip}/#{scm}.scm") )
  end

  def initialize(script_binary)
    self.memory = script_binary.bytes.to_a
    self.pc = 0
    self.stack = []

    tick!
    tick!
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

    self.opcode = read!(2)
    self.args = []

    OPCODE_ARG_COUNTS[opcode].times do
      self.args << read_arg!
    end

    puts "  opcode #{hex(self.opcode)} args: #{self.args.inspect}"

    execute!

    puts "[end of tick]"
    puts
  end

  def execute!
    translated_opcode = hex(self.opcode.reverse).gsub(" ","") # [02 00] => "0002"
    
    send("opcode_#{translated_opcode}",*self.args)
  end

  include Opcodes

  def inspect
    "pc: #{pc}"
  end

  protected

  def read(address,bytes = 1)
    self.memory[(address)...(address+bytes)]
  end

  def read!(bytes = 1)
    ret = read(self.pc,bytes)
    self.pc += bytes
    ret
  end

  def read_arg!
    arg_type = read!(1)[0]
    arg = [arg_type]
    case arg_type
    when 0x01 # immediate 32 bit signed int 
      arg << read!(4)
    end
    arg
  end
end

# 0 - 02 00 01 20 ab 00 00 73 00 00 00 00 00 00 00 00 00
#   opcode 02 00 args: [[1, [32, 171, 0, 0]]]

class Array
  def to_byte_string
    self.map { |byte| byte.chr }.join
  end
end
