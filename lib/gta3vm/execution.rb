
class Gta3Vm::Execution

  include Gta3Vm::Logger

  attr_accessor :vm

  attr_accessor :allocations

  attr_accessor :threads

  attr_accessor :tick_count
  attr_accessor :current_thread_id
  attr_accessor :pc

  def initialize(vm)
    self.vm = vm

    self.allocations = {}
    self.tick_count = 0

    # self.threads = [VmThread.new(vm,self)]
    # self.threads[0].pc = 0
    # self.current_thread_id = 0

    self.pc = 0

    extend vm.opcodes.opcode_module
  end

  def irb
    
  end

  def tick
    instruction = vm.instruction_at(pc)
    result = dispatch_instruction(instruction)
    self.tick_count += 1
    result
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

  # class VmThread
  #   attr_accessor :vm
  #   attr_accessor :execution

  #   attr_accessor :pc

  #   def initialize(vm,execution)
  #     self.vm = vm
  #     self.execution = execution
  #     self.pc = 0
  #   end
  # end

  # Extra features #######

  require "gta3vm/execution/dirty.rb"
  include Gta3Vm::Execution::Dirty
  
end
