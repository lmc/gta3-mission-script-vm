require "ostruct"
class OpenStruct; def to_hash; @table; end; end

TYPE_SHORTHANDS = {
  :int32  => 0x01,
  :bool   => 0x04,
  :int8   => 0x04,
  :int16  => 0x05,
  :string => 0x09
}
GENERIC_TYPE_SHORTHANDS = {
  :int => [:int8,:int16,:int32]
}
COLORS = {
  :opcode => 2,
  :type   => 5,
  :value  => 4
}

load "lib/opcode_dsl.rb"
load "lib/opcodes.rb"

class Vm
  attr_accessor :memory # ""

  attr_accessor :pc # 0
  attr_accessor :stack # []

  attr_accessor :opcode
  attr_accessor :args

  attr_accessor :thread_id # 0
  attr_accessor :thread_names # []

  attr_accessor :missions
  attr_accessor :missions_count

  attr_accessor :progress_count

  def self.load_scm(scm = "main")
    new( File.read("#{`pwd`.strip}/#{scm}.scm") )
  end

  def initialize(script_binary)
    self.memory = script_binary.bytes.to_a
    self.pc = 0
    self.stack = []

    self.thread_id = 0
    self.thread_names = []

    self.missions = []
    self.missions_count = -1

    self.progress_count = -1
  end

  def run
    while tick!; end
  end

  def controlled_ticks
    while gets
      tick!
    end
  end

  def dump_memory_at(address,size = 16)
    start_offset = address
    end_offset = address + size
    "#{address.to_s.rjust(8,"o")} - #{hex self.memory[start_offset..end_offset]}"
  end

  def tick!
    puts dump_memory_at(pc)

    self.opcode = read!(2)
    raise InvalidOpcode, "#{opcode_nice} not implemented" unless Opcodes.definitions[opcode]

    self.args = Opcodes.definitions[opcode][:args_names].map { read_arg! }

    puts "           #{ch(:opcode,opcode)} #{self.args.map{|a| "#{ch(:type,a[0])} #{ch(:value,a[1])}" }.join(" ")}"

    execute!

    puts "[end of tick]"
    puts
    true

  rescue => ex
    puts
    puts "!!! #{ex.class.name}: #{ex.message}"
    puts "VM state:"
    puts "#{self.inspect}"
    puts
    puts "Dump at pc:"
    puts dump_memory_at(pc)
    puts
    puts "Backtrace:"
    puts ex.backtrace.reject{ |l| l =~ %r{(irb_binding)|(bin/irb:)|(ruby/1.9.1/irb)} }.join("\n")
    puts
    false
  end

  def execute!
    definition = Opcodes.definitions[self.opcode]
    translated_opcode = definition[:nice]

    args_helper = OpenStruct.new
    self.args.each_with_index do |(type,value),index|
      validate_arg!(definition[:args_types][index],type)
      arg_struct = OpenStruct.new(:value_bytes => value, :value_native => arg_to_native(type,value))
      args_helper.send("#{definition[:args_names][index]}=",arg_struct)
    end

    opcode_method = "opcode_#{translated_opcode}"
    puts "  #{opcode_method}_#{definition[:sym_name]}(#{args_helper.to_hash.map{|k,v| ":#{k}=>#{v.value_native.inspect}" }.join(',')})"
    
    send(opcode_method,args_helper)
  end

  include Opcodes

  def inspect
    vars_to_inspect = [:pc,:thread_id,:thread_name,:opcode,:opcode_nice,:args,:stack]
    "#<#{self.class.name} #{vars_to_inspect.map{|var| "#{var}=#{send(var).inspect}" }.join(" ") }>"
  end

  def opcode_nice
    arg_to_native(-0x01,self.opcode).to_s(16).rjust(4,"0").upcase
  end

  def thread_name
    self.thread_names[self.thread_id]
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
    when 0x04 # immediate 8-bit signed int
      arg << read!(1)
    when 0x05 # immediate 16 bit signed int 
      arg << read!(2)
    when 0x09 # immediate 8-byte string
      arg << read!(8)
    else
      raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
    end
    arg
  end

  def arg_to_native(arg_type,arg_value)
    case arg_type
    when -0x01 # interal type for opcodes
      arg_value.to_byte_string.unpack("S<")[0]
    when  0x01 # immediate 32 bit signed int
      arg_value.to_byte_string.unpack("l<")[0]
    when  0x04 # immediate 8-bit signed int
      arg_value.to_byte_string.unpack("c")[0]
    when  0x05 # immediate 16 bit signed int 
      arg_value.to_byte_string.unpack("s<")[0]
    when  0x09 # immediate 8-byte string
      arg_value.to_byte_string.strip
    else
      raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
    end
  end

  def validate_arg(expected_arg_type,arg_type)
    allowable_arg_types = GENERIC_TYPE_SHORTHANDS[expected_arg_type] || [expected_arg_type]
    allowable_arg_types.map { |type| TYPE_SHORTHANDS[type] }.include?(arg_type)
  end

  def validate_arg!(expected_arg_type,arg_type)
    if !validate_arg(expected_arg_type,arg_type)
      raise InvalidOpcodeArgumentType, "expected #{arg_type.inspect} to be of type #{expected_arg_type.inspect}"
    end
  end


  def hex(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") }.join(" ")
  end

  def c(type,val)
    "\e[3#{COLORS[type]}m#{val}\e[0m"
  end

  def ch(type,val)
    c(type,hex(val))
  end

  class InvalidOpcode < StandardError; end
  class InvalidOpcodeArgumentType < StandardError; end
  class InvalidDataType < StandardError; end
end

class Array
  def to_byte_string
    self.map { |byte| byte.chr }.join
  end
end
