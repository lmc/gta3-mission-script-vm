class Gta3Vm::Execution

  attr_accessor :vm

  attr_accessor :threads

  attr_accessor :current_thread_id
  attr_accessor :pc

  def initialize(vm)
    self.vm = vm

    # self.threads = [VmThread.new(vm,self)]
    # self.threads[0].pc = 0
    # self.current_thread_id = 0

    self.pc = 0

    extend vm.opcodes.opcode_module
  end

  def tick
    instruction = vm.instruction_at(pc)
    dispatch_instruction(instruction)
  end

  def dispatch_instruction(instruction)
    definition = vm.opcodes.definition_for(instruction.opcode)
    method_name = definition.nice
    send("opcode_#{method_name}",ArgWrapper.new(definition,instruction.args))
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
      if index = definition.args_names.index(symbol)
        Gta3Vm::Vm::DataTypeMethods.arg_to_native(args[index])
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
  
end
