
# (load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc)

# vm = Gta3Vm::Vm.new(bytecode: "bytecode", game: "vc")

# VM
# MemorySpace # 
# [ByteCode]

class Gta3Vm::Vm
end

require 'ostruct'
require 'active_support/concern'
require 'active_support/core_ext/class/attribute'

require "gta3vm/core_extensions.rb"
require "gta3vm/vm_vice_city.rb"
require "gta3vm/logger.rb"
require "gta3vm/memory.rb"
require "gta3vm/opcode_definition.rb"
require "gta3vm/opcodes.rb"
require "gta3vm/instruction.rb"
require "gta3vm/execution.rb"
require "gta3vm/vm/helpers.rb"
require "gta3vm/vm/data_type_methods.rb"
require "gta3vm/instrumentation.rb"


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

  def execute(&block)
    execution = Gta3Vm::Execution.new(self)
    if block_given?
      begin
        yield(execution)
      rescue => ex
        log "!!! VM EXCEPTION !!! #{ex.message}"
        log "VM state: pc #{execution.pc} (#{memory.read(execution.pc - 4,4 + 8).inspect})"
        raise
      end
    else
      execution
    end
  end

  def instruction_at(offset)
    opcode = memory.read(offset,2)

    unless definition = opcodes.definition_for(opcode)
      raise InvalidOpcode, hex(opcode)
    end

    offset += 2
    instruction = Gta3Vm::Instruction.new
    instruction.opcode = opcode

    definition.args_names.each do |arg_name|
      # log "instruction_at: #{arg_name}"
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
    instruction_arg_at_type(type,offset)
  end

  def instruction_arg_at_type(type,offset)
    type = Gta3Vm::Vm::DataTypeMethods::TYPE_SHORTHANDS[type] if type.is_a?(Symbol)
    bytes = bytes_to_read_for_arg_data_type(type,offset)
    Gta3Vm::Instruction::Arg.new([type,memory.read(offset + 1,bytes)])
  end


  # ####################

  class InvalidScmStructure < StandardError; end
  class InvalidOpcode < StandardError; end
  class InvalidOpcodeArgumentType < StandardError; end
  class InvalidDataType < StandardError; end

  class InvalidBranchConditionState < StandardError; end

  # ####################

  include DataTypeMethods

  # ####################

  include Helpers

  # ####################

  def self.new_for_vc
    Gta3Vm::VmViceCity.new(bytecode: File.read("./main-vc.scm"))
  end

  def self.scm_markers
    raise "abstract"
  end


end
