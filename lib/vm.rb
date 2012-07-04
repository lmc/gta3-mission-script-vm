require "ostruct"
class OpenStruct; def to_hash; @table; end; end

TYPE_SHORTHANDS = {
  :int32 => 0x01
}

load "lib/opcode_dsl.rb"
load "lib/opcodes.rb"

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
  end

  def controlled_ticks
    while gets
      tick!
    end
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

    raise "Opcode not implemented" unless Opcodes.definitions[opcode]

    Opcodes.definitions[opcode][:args_count].times do
      self.args << read_arg!
    end

    puts "  opcode: #{hex(self.opcode)}, args: #{self.args.map{ |a| [hex([a[0]]), hex(a[1]) ]}.inspect}"

    execute!

    puts "[end of tick]"
    puts

  rescue => ex
    puts "!!! Exception: #{ex.message}"
    puts "VM state:"
    puts "  #{self.inspect}"
    puts "Dump at pc:"
    dump_memory_at(pc)
    puts "Backtrace:"
    puts ex.backtrace.join("\n")
    ex
  end

  def execute!
    definition = Opcodes.definitions[self.opcode]
    translated_opcode = definition[:nice]

    args_helper = OpenStruct.new
    self.args.each_with_index do |(type,value),index|
      expected_arg_type = definition[:args_types][index]
      raise ArgumentError, "#{translated_opcode} arg #{index}, type #{type} != #{expected_arg_type}" if type != expected_arg_type
      arg_struct = OpenStruct.new(:value_bytes => value, :value_native => arg_to_native(type,value))
      args_helper.send("#{definition[:args_names][index]}=",arg_struct)
    end

    opcode_method = "opcode_#{translated_opcode}"
    puts "  #{opcode_method}(#{args_helper.to_hash.map{|k,v| ":#{k}=>#{v.value_native}" }.join(',')})"
    
    send(opcode_method,args_helper)
  end

  include Opcodes

  def inspect
    vars_to_inspect = [:pc,:opcode,:opcode_nice,:args,:stack]
    "#<#{self.class.name} #{vars_to_inspect.map{|var| "#{var}=#{send(var).inspect}" }.join(" ") }>"
  end

  def opcode_nice
    arg_to_native(-0x01,self.opcode).to_s(16)
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

  def arg_to_native(arg_type,arg_value)
    case arg_type
    when -0x01 #interal type for opcodes
      arg_value.to_byte_string.unpack("S<")[0]
    when  0x01
      arg_value.to_byte_string.unpack("l<")[0]
    end
  end
end

class Array
  def to_byte_string
    self.map { |byte| byte.chr }.join
  end
end
