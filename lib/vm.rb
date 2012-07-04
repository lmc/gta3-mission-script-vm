require "ostruct"
class OpenStruct; def to_hash; @table; end; end

TYPE_SHORTHANDS = {
  :int32   => 0x01,
  :pg_if   => 0x02,
  :bool    => 0x04,
  :int8    => 0x04,
  :int16   => 0x05,
  :float32 => 0x06,
  :string  => 0x09
}
POINTER_TYPES = {
  :pg_if => { :scope => :global, :size => 4 }
}
TYPE_SIZES = {
  0x01 => 4,
  0x02 => 4,
  0x04 => 1,
  0x05 => 2,
  0x09 => nil # ???
}
GENERIC_TYPE_SHORTHANDS = {
  :int   => [:int8,:int16,:int32],
  :float => [:float32]
}
OPCODE = -0x02
TYPE   = -0x03
VALUE  = -0x04
COLORS = {
  OPCODE => "0;30;42",
  TYPE   => "0;30;45",
  VALUE  => "0;30;44",
  0x01   => "4;34",
  0x02   => "4;32"
}

load "lib/player.rb"
load "lib/opcode_dsl.rb"
load "lib/opcodes.rb"

# (load("lib/vm.rb") && Vm.load_scm("main").run)

class Vm
  attr_accessor :memory # ""

  attr_accessor :pc # 0
  attr_accessor :stack # []

  attr_accessor :opcode
  attr_accessor :args

  attr_accessor :thread_id
  attr_accessor :thread_names

  attr_accessor :missions
  attr_accessor :missions_count

  attr_accessor :engine_vars

  attr_accessor :allocations, :allocation_ids

  attr_accessor :players

  DATA_TYPE_MAX = 31
  VARIABLE_STORAGE_AT = 8

  def self.load_scm(scm = "main")
    new( File.read("#{`pwd`.strip}/#{scm}.scm") )
  end

  def initialize(script_binary)
    self.memory = script_binary.bytes.to_a
    self.pc = 0
    self.stack = []

    self.thread_id = 0
    self.thread_names = []

    self.engine_vars = OpenStruct.new

    self.allocations = {} # address => [pointer_type,id]
    self.allocation_ids = Hash.new { |h,k| h[k] = 0 }

    self.players = {}
  end

  def run
    while tick!; end
  end

  def controlled_ticks
    while gets; tick!; end
  end

  def dump_memory_at(address,size = 16,previous_context = 0,shim_range = nil,shim = nil) #yield(buffer)
    dump = ""
    offset = address-previous_context
    same_colour_left = -1
    while offset < address+size-previous_context

      if shim_range && offset == (address+shim_range.begin)
        dump << shim
        dump << " " unless [2].include?(shim_range.end) #why? no idea
        offset = (address+shim_range.end)
        next
      end

      if self.allocations[offset]
        alloc_colour = COLORS[ self.allocations[offset][0] ]
        same_colour_left = TYPE_SIZES[ self.allocations[offset][0] ]
        dump << "\e[#{alloc_colour}m"
      end

      dump << hex(self.memory[offset])
      same_colour_left -= 1

      if same_colour_left == 0
        dump << "\e[0m"
      end

      dump << " "
      offset += 1
    end

    yield(dump) if block_given?

    "#{address.to_s.rjust(8,"o")} - #{dump}"
  end

  def tick!
    mem_width = 40

    opcode_start_address = self.pc
    self.opcode, self.args = read!(2), []
    raise InvalidOpcode, "#{opcode_nice} not implemented" unless Opcodes.definitions[opcode]

    self.args = Opcodes.definitions[opcode][:args_names].map { read_arg! }

    opcode_prelude = 4
    shim_size = (0)...([opcode,args].flatten.compact.size)
    shim = "#{ch(OPCODE,opcode)} #{self.args.map{|a| "#{ch(TYPE,a[0])} #{ch(VALUE,a[1])}" }.join(" ")}"
    puts " thread #{self.thread_id.to_s.rjust(2," ")} @ #{opcode_start_address.to_s.rjust(8,"0")} v"
    puts dump_memory_at(opcode_start_address,mem_width,opcode_prelude,shim_size,shim)

    execute!

    width,rows = mem_width, 2
    rows.times do |index|
      puts dump_memory_at(VARIABLE_STORAGE_AT+(index*width),width)
    end

    puts; true
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
      validate_arg!(definition[:args_types][index],type,translated_opcode,index)
      args_helper.send("#{definition[:args_names][index]}=",arg_to_native(type,value))
    end

    opcode_method = "opcode_#{translated_opcode}"
    puts "  #{opcode_method}_#{definition[:sym_name]}(#{args_helper.to_hash.map{|k,v| ":#{k}=>#{v.inspect}" }.join(',')})"
    
    send(opcode_method,args_helper)
  end

  include Opcodes

  def inspect
    vars_to_inspect = [:pc,:thread_id,:thread_name,:opcode,:opcode_nice,:args,:stack]
    vars_to_inspect += instance_variables.map { |iv| iv.to_s.gsub(/@/,"").to_sym }
    vars_to_inspect -= [:memory]
    vars_to_inspect.uniq!
    "#<#{self.class.name} #{vars_to_inspect.map{|var| "#{var}=#{send(var).inspect}" }.join(" ") }>"
  end

  def opcode_nice
    arg_to_native(-0x01,self.opcode).to_s(16).rjust(4,"0").upcase
  end

  def thread_name
    self.thread_names[self.thread_id]
  end

  protected

  # for initializing "objects" like players/actors/etc.
  # in the real game, we would normally be writing a pointer to a native game object
  # but instead, we'll just auto-increment an id and store that, referencing things by their address instead
  # for things like ints/floats/strings, we'll store the real value
  def allocate!(address,data_type,value = nil)
    data_type = TYPE_SHORTHANDS[data_type] if data_type.is_a?(Symbol)
    size = TYPE_SIZES[data_type]

    to_write = if value
      allocation_id = nil # immediate value
      native_to_arg_value(data_type,value)
    else
      allocation_id = self.allocation_ids[data_type] += 1
      [allocation_id].pack("l<").bytes.to_a
    end

    self.allocations[address] = [data_type,allocation_id]

    #puts "  #{address} - #{self.allocations[address].inspect}"
    #puts "  #{[address,size,to_write].inspect}"

    write!(address,size,to_write)
  end

  def write!(address,bytes,byte_array)
    self.memory[(address)...(address+bytes)] = byte_array[0...bytes]
  end

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
    when 0x02 # 16-bit global pointer to int/float
      arg << read!(2)
    when 0x04 # immediate 8-bit signed int
      arg << read!(1)
    when 0x05 # immediate 16-bit signed int 
      arg << read!(2)
    when 0x06 # immediate 32-bit float
      arg << read!(4)
    when 0x09 # immediate 8-byte string
      arg << read!(8)
    else
      if arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
        arg << read!(7)
      else
        raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
      end
    end
    arg
  end

  # p much everything is little-endian
  def arg_to_native(arg_type,arg_value)
    case arg_type
    when -0x01 # interal type for opcodes
      arg_value.to_byte_string.unpack("S<")[0]
    when  0x01 # immediate 32 bit signed int
      arg_value.to_byte_string.unpack("l<")[0]
    when 0x02 # 16-bit global pointer to int/float
      arg_value.to_byte_string.unpack("S<")[0]
    when  0x04 # immediate 8-bit signed int
      arg_value.to_byte_string.unpack("c")[0]
    when  0x05 # immediate 16 bit signed int 
      arg_value.to_byte_string.unpack("s<")[0]
    when  0x06 # immediate 32-bit float
      arg_value.to_byte_string.unpack("e")[0]
    when  0x09 # immediate 8-byte string
      arg_value.to_byte_string.strip
    else
      if arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
        [arg_type,arg_value].flatten.to_byte_string.strip #FIXME: can have random crap after first null byte, cleanup
      else
        raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
      end
    end
  end

  def native_to_arg_value(arg_type,native)
    native = [native]
    arg_type = TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)
    pack_char = case arg_type
    when  0x01 # immediate 32 bit signed int
      "l<"
    when  0x05 # immediate 16 bit signed int 
      "s<"
    when  0x06 # immediate 32-bit float
      "e"
    else
      raise InvalidDataType, "native_to_arg_value: unknown data type #{arg_type} (#{hex(arg_type)})"
    end
    native.pack(pack_char).bytes.to_a
  end

  def validate_arg(expected_arg_type,arg_type)
    return true if expected_arg_type == :string && arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
    allowable_arg_types = GENERIC_TYPE_SHORTHANDS[expected_arg_type] || [expected_arg_type]
    allowable_arg_types.map { |type| TYPE_SHORTHANDS[type] }.include?(arg_type)
  end

  def validate_arg!(expected_arg_type,arg_type,opcode,arg_index)
    if !validate_arg(expected_arg_type,arg_type)
      raise InvalidOpcodeArgumentType, "expected #{arg_type.inspect} = #{expected_arg_type.inspect} (#{opcode} @ #{arg_index})"
    end
  end


  def hex(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") }.join(" ")
  end

  def c(type,val)
    "\e[#{COLORS[type]}m#{val}\e[0m"
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
