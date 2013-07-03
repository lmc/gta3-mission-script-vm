
class Gta3Vm::Execution

  include Gta3Vm::Logger

  attr_accessor :vm

  attr_accessor :allocations

  attr_accessor :threads

  attr_accessor :tick_count
  attr_accessor :thread_id
  attr_accessor :pc

  def initialize(vm)
    self.vm = vm
    reset
    extend vm.opcodes.opcode_module
  end

  def reset
    log "reset"
    self.allocations = {}
    self.tick_count = 0

    self.threads = [VmThread.new(vm,self)]
    self.threads[0].pc = 0
    self.thread_id = 0
  end

  def irb
    
  end

  def tick
    instruction_pos = self.pc
    instruction = vm.instruction_at(instruction_pos)
    result = dispatch_instruction(instruction)
    self.pc = instruction_pos + instruction.size if self.pc == instruction_pos # advance past instruction if we haven't manually jumped
    self.tick_count += 1
    result
  end

  def pc
    self.threads[self.thread_id].pc
  end

  def pc=(value)
    self.threads[self.thread_id].pc = value
  end

  def dispatch_instruction(instruction)
    definition = vm.opcodes.definition_for(instruction.opcode)
    method_name = definition.nice
    log "#{pc}\t:#{definition.nice}(#{instruction.args.inspect})"
    send("opcode_#{method_name}",ArgWrapper.new(definition,instruction.args))
  end

  def allocate(address,data_type,value = nil)
    raise ArgumentError, "address is nil" unless address
    raise ArgumentError, "data_type is nil" unless data_type
    size = 4

    to_write = vm.native_to_arg_value(data_type,value)
    raise ArgumentError, "incorrect size #{to_write.inspect}" unless to_write.size == size

    self.allocations[address] = data_type
    write(address,size,to_write)
  end

  def write(address,size,to_write)
    puts "write"
    vm.memory.write(address,size,to_write)
  end


  # #####################

  class ArgWrapper
    attr_accessor :definition
    attr_accessor :args

    def initialize(definition,args)
      self.definition = definition
      self.args = args
    end

    def method_missing(symbol,*arguments)
      type = nil
      if symbol.to_s.match(/(.+?)(_(type))?$/)
        type = $3
        symbol = $1.to_sym
      end
      # puts "ArgWrapper: #{symbol} #{type} #{index} #{args.inspect}"
      if index = definition.args_names.index(symbol)
        if type == "type"
          args[index].type
        else
          Gta3Vm::Vm::DataTypeMethods.arg_to_native(args[index])
        end
      end
    end
  end

  # #####################

  class VmThread
    attr_accessor :vm
    attr_accessor :execution

    attr_accessor :pc
    attr_accessor :name

    def initialize(vm,execution)
      self.vm = vm
      self.execution = execution
      self.pc = 0
    end
  end

  # Extra features #######

  require "gta3vm/execution/dirty.rb"
  include Gta3Vm::Execution::Dirty
  
end
