require "ostruct"
class OpenStruct; def to_hash; @table; end; end

TYPE_SHORTHANDS = {
  :int32   => 0x01,
  :pg_if   => 0x02,
  :bool    => 0x04,
  :int8    => 0x04,
  :int16   => 0x05,
  :float32 => 0x06,
  :string  => 0x09,
  :vstring => 0x0e
}
POINTER_TYPES = {
  :pg_if => { :scope => :global, :size => 4 }
}
TYPE_SIZES = {
  0x01 => 4,
  0x02 => 4,
  0x04 => 1,
  0x05 => 2,
  0x06 => 4,
  0x09 => nil, # ???
  0x0e => lambda {},
}
GENERIC_TYPE_SHORTHANDS = {
  :int    => [:int8,:int16,:int32],
  :float  => [:float32],
  :string => [:string,:vstring],
  :var    => [:pg_if]
}
GENERIC_TYPE_SHORTHANDS[:int_or_float] = GENERIC_TYPE_SHORTHANDS[:int] + GENERIC_TYPE_SHORTHANDS[:float]
GENERIC_TYPE_SHORTHANDS[:int_or_var] = GENERIC_TYPE_SHORTHANDS[:int] + GENERIC_TYPE_SHORTHANDS[:var]
OPCODE = -0x02
TYPE   = -0x03
VALUE  = -0x04
COLORS = {
  OPCODE => "0;30;42",
  TYPE   => "0;30;45",
  VALUE  => "0;30;44",
  0x01   => "4;34", # int val = blue
  0x02   => "4;32", # pointer = green
  0x04   => "4;34",
  0x06   => "4;33", #float val = yellow
}
DEFAULT_COLOR = "7"

load "lib/game_objects/game_object.rb"
load "lib/game_objects/player.rb"
load "lib/game_objects/actor.rb"
load "lib/game_objects/pickup.rb"
load "lib/game_objects/cargen.rb"
load "lib/opcode_dsl.rb"
load "lib/opcodes.rb"

# (load("lib/vm.rb") && Vm.load_scm("main-vc").run)

class Vm
  attr_accessor :memory # ""

  attr_accessor :pc # 0
  attr_accessor :stack # []

  attr_accessor :original_opcode
  attr_accessor :opcode
  attr_accessor :args

  attr_accessor :thread_id
  attr_accessor :thread_pcs
  attr_accessor :thread_names
  attr_accessor :thread_suspended
  attr_accessor :thread_switch_to_id

  attr_accessor :negated_opcode
  attr_accessor :branch_conditions

  attr_accessor :missions
  attr_accessor :missions_count

  attr_accessor :engine_vars

  attr_accessor :allocations, :allocation_ids

  attr_accessor :onmission_address
  attr_accessor :game_objects

  attr_accessor :scm_structures

  attr_accessor :opcode_map

  attr_accessor :tick_count
  attr_accessor :dirty

  DATA_TYPE_MAX = 31
  VARIABLE_STORAGE_AT = 8
  NEGATED_OPCODE_MASK = 0x80

  DIRTY_STATES = [:threads,:memory,:game_objects,:map]

  def self.load_scm(scm = "main-vc")
    new( File.read("#{`pwd`.strip}/#{scm}.scm") )
  end

  def initialize(script_binary)
    self.memory = Memory.new(script_binary)
    #self.memory = script_binary.bytes.to_a
    self.pc = 0
    self.stack = []

    self.thread_id = 0
    self.thread_pcs = [0]
    self.thread_names = []
    self.thread_suspended = false

    self.engine_vars = OpenStruct.new

    self.allocations = {} # address => [pointer_type,id]
    self.allocation_ids = Hash.new { |h,k| h[k] = 0 }

    self.game_objects = {}

    self.tick_count = 0
    self.dirty = {}

    detect_scm_structures!
    build_opcode_map!
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
        alloc_colour = COLORS[ self.allocations[offset][0] ] || DEFAULT_COLOR
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
    self.tick_count += 1
    reset_dirty_state
    
    mem_width = 32#40

    self.negated_opcode = false
    self.pc = self.thread_pcs[self.thread_id]

    opcode_start_address = self.pc

    self.opcode, self.args = read!(2), []
    self.original_opcode = self.opcode.dup

    # Conditional opcodes can have the highest bit of the opcode set to 1
    # So they look like 8038 instead of 0038
    # This is basically a NOT version of the normal opcode
    # We should detect this here, set a flag to say the next write_branch_condition call
    # should be negated, and remove the high bit on the opcode so it calls the "plain" opcode
    if self.opcode[1] >= NEGATED_OPCODE_MASK
      self.opcode[1] -= NEGATED_OPCODE_MASK
      self.negated_opcode = true
    end

    raise InvalidOpcode, "#{opcode_nice} not implemented" unless Opcodes.definitions[opcode]

    self.args = read_args!

    opcode_prelude = 4
    shim_size = (0)...([opcode,args].flatten.compact.size)
    shim = "#{ch(OPCODE,original_opcode)} #{self.args.map{|a| "#{ch(TYPE,a[0])} #{a[1] ? ch(VALUE,a[1]) : '00'}" }.join(" ")}"
    puts " thread #{self.thread_id.to_s.rjust(2," ")} @ #{opcode_start_address.to_s.rjust(8,"0")} v (threadname:#{(self.thread_names[self.thread_id] || "-")} branch_conditions:#{self.branch_conditions.inspect} negated_opcode:#{self.negated_opcode.inspect})"
    puts dump_memory_at(opcode_start_address,mem_width,opcode_prelude,shim_size,shim)

    execute!

    width,rows = mem_width, 0
    rows.times do |index|
      puts dump_memory_at(VARIABLE_STORAGE_AT+(index*width),width)
    end
    puts dump_memory_at(3530,32)

    self.thread_pcs[self.thread_id] = self.pc
    if self.thread_suspended
      puts "  suspended"
      until self.thread_switch_to_id && self.thread_pcs[self.thread_switch_to_id]
        self.thread_switch_to_id = (self.thread_id + 1) % self.thread_pcs.size
      end
      self.thread_suspended = false
    end
    if self.thread_switch_to_id
      puts " switching to thread #{self.thread_switch_to_id}"
      self.thread_id = self.thread_switch_to_id
      self.thread_switch_to_id = false
    end

    self.dirty[:threads] = true
    self.dirty[:game_objects] = self.game_objects.values.any?(&:dirty_check!)

    puts; true
  rescue => ex
    self.pc -= 2 if [InvalidOpcode].include?(ex.class) #rewind so we get the opcode in the dump
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
    raise ex
  end

  def execute!
    definition = Opcodes.definitions[self.opcode]
    translated_opcode = definition[:nice]

    # TODO: will this actually handle variable-length arg lists?
    native_args = []
    self.args.each_with_index do |(type,value),index|
      validate_arg!(definition[:args_types][index],type,translated_opcode,index)

      if type == 0x00 # end of variable-length arg list
        start_arg = definition[:args_names].index(:var_args)
        native_args[start_arg..-1] = [[:var_args,0x00,native_args[start_arg..-1]]]
      else
        native_args << [ definition[:args_names][index], type, arg_to_native(type,value) ]
      end
    end

    args_helper = OpcodeArgs.new
    native_args.each do |(name,type,native_value)|
      if native_value.is_a?(Array)
        args_helper.add_arg("var_args",native_value.map{ |a| a[1] },native_value.map{ |a| a[2] })
        #args_helper.send("var_args=",native_value.map{ |a| a[2] })
        #args_helper.send("var_args_type=",native_value.map{ |a| a[1] })
      else
        args_helper.add_arg(name,type,native_value)
        #args_helper.send("#{name}=",native_value)
        #args_helper.send("#{name}_type=",type)
      end
    end

    opcode_method = "opcode_#{translated_opcode}"
    nice_args = args_helper.to_hash.reject{|k,v| k =~ /_type$/}.map{|k,v| ":#{k}=>#{v.inspect}" }
    puts "  #{opcode_method}_#{definition[:sym_name]}(#{nice_args.join(',')})"
    
    send(opcode_method,args_helper)
  end

  include Opcodes

  def inspect
    vars_to_inspect = [:pc,:opcode,:opcode_nice,:args,:thread_id,:thread_pcs,:stack,:branch_conditions]
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

  #protected

  def allocate_game_object!(address,game_object_class,pointer_type = :pg_if,&block)
    self.game_objects[address] = game_object_class.new
    allocate!(address,pointer_type,game_object_class)
    yield(self.game_objects[address]) if block_given?
  end

  # for initializing "objects" like players/actors/etc.
  # in the real game, we would normally be writing a pointer to a native game object
  # but instead, we'll just auto-increment an id and store that, referencing things by their address instead
  # for things like ints/floats/strings, we'll store the real value
  def allocate!(address,data_type,value = nil)
    data_type = TYPE_SHORTHANDS[data_type] if data_type.is_a?(Symbol)
    size = TYPE_SIZES[data_type]
    klass = nil
    raise ArgumentError, "address is nil" unless address
    raise ArgumentError, "data_type is nil" unless data_type

    to_write = if !value.is_a?(Class)
      allocation_id = nil # immediate value
      native_to_arg_value(data_type,value)
    else
      klass = value
      allocation_id = self.allocation_ids[data_type] += 1
      [allocation_id].pack("l<").bytes.to_a
    end

    self.allocations[address] = [data_type,allocation_id,klass]
    # puts "  #{address} - #{self.allocations[address].inspect}"
    # puts "  #{[address,size,to_write].inspect}"

    write!(address,size,to_write)
  end

  def write!(address,bytes,byte_array)
    self.memory[(address)...(address+bytes)] = byte_array[0...bytes]
    self.dirty[:memory] = true
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
    when 0x0e # variable-length string
      string_length = read!(1)[0]
      arg << read!(string_length)
    else
      if arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
        arg << read!(7)
      else
        raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
      end
    end
    arg
  end

  def read_args!
    arg_def = Opcodes.definitions[opcode]
    args = []
    arg_def[:args_count].times do |index|
      if arg_def[:args_names][index] == :var_args
        args << read_arg! while read(1)[0] != 0x00
        args << read!(1)
      else
        args << read_arg!
      end
    end
    args
  end

  def write_branch_condition!(bool)
    raise InvalidBranchConditionState, "called conditional opcode outside of if structure" if self.branch_conditions.nil?
    next_insert = self.branch_conditions.index(nil)
    raise InvalidBranchConditionState, "too many conditional opcodes (allocated: #{self.branch_conditions.size}" if next_insert >= self.branch_conditions.size
    bool = !bool if self.negated_opcode
    self.branch_conditions[next_insert] = bool
  end

  # p much everything is little-endian
  def arg_to_native(arg_type,arg_value)
    arg_type = TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)
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
      arg_value.to_byte_string.strip_to_null
    when  0x0e # variable-length string
      arg_value.to_byte_string[1..-1].strip_to_null
    else
      if arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
        [arg_type,arg_value].flatten.to_byte_string.strip_to_null #FIXME: can have random crap after first null byte, cleanup
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
    when  0x04 # immediate 8-bit signed int
      "c"
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
    return true if expected_arg_type == -1 # don't care what the arg type is
    return true if expected_arg_type == true && arg_type == 0x00 # end of variable-length arg list
    return true if expected_arg_type == :string && arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
    allowable_arg_types = GENERIC_TYPE_SHORTHANDS[expected_arg_type] || [expected_arg_type]
    allowable_arg_types.map { |type| TYPE_SHORTHANDS[type] }.include?(arg_type)
  end

  def validate_arg!(expected_arg_type,arg_type,opcode,arg_index)
    if !validate_arg(expected_arg_type,arg_type)
      raise InvalidOpcodeArgumentType, "expected #{arg_type.inspect} = #{expected_arg_type.inspect} (#{opcode} @ #{arg_index})"
    end
  end

  def detect_scm_structures!
    
  end

  def build_opcode_map!
    # For disassembly purposes, we need to know where an opcode begins
    # ignoring the special structures at the start of the SCM (memory, object table, mission table, etc.)
    # starting from the first opcode, record it's start address, fast-forward through the size of it's args to find the next opcode, repeat
    # will need to know arg counts for all opcodes, and size of all datatypes, with special handling for var_args
  end

  def start_of_opcode_at(address)
    map_index = self.opcode_map.size
    map_index -= 1 until self.opcode_map[map_index] >= address
    self.opcode_map[map_index]
  end


  def reset_dirty_state
    DIRTY_STATES.each { |state| self.dirty[state] = false }
  end


  def hex(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") }.join(" ")
  end

  def c(type,val)
    "\e[#{COLORS[type] || DEFAULT_COLOR}m#{val}\e[0m"
  end

  def ch(type,val)
    c(type,hex(val))
  end

  class InvalidOpcode < StandardError; end
  class InvalidOpcodeArgumentType < StandardError; end
  class InvalidDataType < StandardError; end

  class InvalidBranchConditionState < StandardError; end
end

class Memory < String
  def initialize(*args)
    super(*args)
    self.force_encoding("ASCII-8BIT")
  end

  def [](args = nil)
    super.bytes.to_a
  end

  def []=(pos,args)
    args = args.to_byte_string if args.is_a?(Array) && args[0].is_a?(Numeric)
    super(pos,args)
  end
end

class OpcodeArgs < OpenStruct
  def initialize(*args)
    super
    self.arg_names = []
  end
  def add_arg(arg_name,data_type,value)
    self.arg_names << arg_name
    send("#{arg_name}=",value)
    send("#{arg_name}_type=",data_type)
  end
end

class String
  def strip_to_null
    temp = self.bytes.to_a
    null_index = temp.index(0)
    temp[0...null_index].to_byte_string
    #gsub(/#{0x00}.+$/,"")
  end
end

class Array
  def to_byte_string
    self.map { |byte| byte.chr }.join
  end
end
