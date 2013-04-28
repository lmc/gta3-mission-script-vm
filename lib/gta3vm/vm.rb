
# (load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc)

# vm = Gta3Vm::Vm.new(bytecode: "bytecode", game: "vc")

# VM
# MemorySpace # 
# [ByteCode]

class Gta3Vm::Vm
end

require 'ostruct'

require "gta3vm/core_extensions.rb"
require "gta3vm/vm_vice_city.rb"
require "gta3vm/logger.rb"
require "gta3vm/memory.rb"
require "gta3vm/vm/opcode_definition.rb"
require "gta3vm/vm/opcodes.rb"
require "gta3vm/vm/instruction.rb"


# load "lib/gta3vm/core_extensions.rb"
# load "lib/gta3vm/vm_vice_city.rb"
# load "lib/gta3vm/logger.rb"
# load "lib/gta3vm/memory.rb"
# load "lib/gta3vm/vm/opcode_definition.rb"
# load "lib/gta3vm/vm/opcodes.rb"
# load "lib/gta3vm/vm/instruction.rb"


class Gta3Vm::Vm

  include Gta3Vm::Logger

  attr_accessor :memory
  attr_accessor :opcodes

  def initialize(options = {})
    options.reverse_merge!(
      bytecode: nil
    )

    self.opcodes = Gta3Vm::Opcodes.new(self)

    self.memory = Gta3Vm::Memory.new(self,options[:bytecode])
    self.memory.detect_structure if self.memory.has_structure?
  end

  def instruction_at(offset)
    opcode = memory.read(offset,2)

    unless definition = opcodes.definition_for(opcode)
      raise InvalidOpcode, hex(opcode.reverse)
    end

    offset += 2
    instruction = Gta3Vm::Vm::Instruction.new
    instruction.opcode = opcode

    definition.args_names.each do |arg_name|
      log "instruction_at: #{arg_name}"
      # HACK: var_args is a magic arg name for opcodes that take a variable number of arguments
      if arg_name == :var_args
        # read normal args up until an arg with the data_type 0x00
        until memory.read(offset,1) == [0x00]
          instruction.args << instruction_arg_at(offset)
          offset += instruction.args.last.size
        end
        # read the data_type 0x00 in as an arg anyway
        instruction.args << memory.read(offset,1)
        offset += 1
      else
        instruction.args << instruction_arg_at(offset)
        offset += instruction.args.last.size
      end
    end

    instruction
  end

  def instruction_arg_at(offset)
    type = memory.read(offset,1)[0]
    bytes = bytes_to_read_for_arg_data_type(offset)
    Gta3Vm::Vm::Instruction::Arg.new([type,memory.read(offset + 1,bytes)])
  end

  def bytes_to_read_for_arg_data_type(offset)
    arg_type = memory.read(offset,1)[0]
    case arg_type
    when 0x01 # immediate 32 bit signed int
      4
    when 0x02 # 16-bit global pointer to int/float
      2
    when 0x03 # 16-bit local pointer to int/float
      2
    when 0x04 # immediate 8-bit signed int
      1
    when 0x05 # immediate 16-bit signed int 
      2
    when 0x06 # immediate 32-bit float
      4
    when 0x09 # immediate 8-byte string
      8
    when 0x0e # variable-length string
      memory.read(offset + 1,1)[0] + 1 #+1 to read the var string length prefix too
    else
      if arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
        7
      else
        raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
      end
    end
  end

  DATA_TYPE_MAX = 31
  TYPE_SHORTHANDS = {
    :int32   => 0x01,
    :pg      => 0x02, # all "pointers" are to ints or floats
    :bool    => 0x04,
    :int8    => 0x04,
    :int16   => 0x05,
    :float32 => 0x06,
    :string  => 0x09,
    :vstring => 0x0e
  }
  PACK_CHARS_FOR_DATA_TYPE = {
   -0x01 => "S<",
    0x01 => "l<",
    0x02 => "S<",
    0x03 => "S<",
    0x04 => "c",
    0x05 => "s<",
    0x06 => "e"
  }
  FLOAT_PRECISION = 3
  # p much everything is little-endian
  def arg_to_native(arg)
    log "arg_to_native: #{arg.inspect}"
    return nil if arg.type == 0x00

    # arg_type = TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)

    value = if pack_char = PACK_CHARS_FOR_DATA_TYPE[arg.type]
      value = arg.value.to_byte_string.unpack( PACK_CHARS_FOR_DATA_TYPE[arg.type] )[0]
      value
    else

      case arg.type
      when  0x09 # immediate 8-byte string
        arg.value.to_byte_string.strip_to_null
      when  0x0e # variable-length string
        arg.value.to_byte_string[1..-1]
      else
        if arg.type > DATA_TYPE_MAX # immediate type-less 8-byte string
          [arg.type,arg.value].flatten.to_byte_string.strip_to_null #FIXME: can have random crap after first null byte, cleanup
        else
          raise InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
        end
      end

    end

    value = value.round(FLOAT_PRECISION) if value.is_a?(Float)

    value

  end


  # ####################

  def hex(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") }.join(" ")
  end


  # ####################

  def self.new_for_vc
    Gta3Vm::VmViceCity.new(bytecode: File.read("./main-vc.scm"))
  end

  def self.scm_markers
    raise "abstract"
  end


  # ####################

  class InvalidScmStructure < StandardError; end
  class InvalidOpcode < StandardError; end
  class InvalidOpcodeArgumentType < StandardError; end
  class InvalidDataType < StandardError; end

  class InvalidBranchConditionState < StandardError; end

end
