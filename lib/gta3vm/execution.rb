
class Gta3Vm::Execution

  include Gta3Vm::Logger

  attr_accessor :vm

  attr_accessor :allocations

  attr_accessor :threads

  attr_accessor :tick_count
  attr_accessor :thread_id
  attr_accessor :pc
  attr_accessor :realtime

  attr_accessor :switch_on_new_thread

  attr_accessor :current_instruction
  attr_accessor :dispatched_method
  attr_accessor :dispatched_args

  def initialize(vm)
    self.vm = vm
    reset
    extend vm.opcodes.opcode_module
  end

  def reset
    log "reset"
    self.allocations = {}
    self.tick_count = 0

    self.threads = []
    thread_create(0)
    self.thread_id = 0

    self.realtime = 0

    self.switch_on_new_thread = true
  end

  def irb
    
  end

  def tick
    instruction_pos = self.pc
    instruction_thread = self.thread_id
    self.current_instruction = vm.instruction_at(instruction_pos)
    result = dispatch_instruction(current_instruction)

    # advance past instruction if we haven't manually jumped
    if self.threads[instruction_thread].pc == instruction_pos
      self.threads[instruction_thread].pc = instruction_pos + current_instruction.size
    end

    self.realtime += 1
    self.tick_count += 1
    result
  end

  def thread_create(pc,is_mission = false)
    self.threads << VmThread.new(vm,self,pc,is_mission)
    # self.thread_id = self.threads.size - 1 if self.switch_on_new_thread
    self.thread_pass if self.switch_on_new_thread
  end

  def thread_pass
    # thread 1 - RT: 150 - sleep 250, idleuntil 400
    # thread 2 - RT: 150 - sleep 350, idleuntil 500
    # thread 3 - RT: 150 -            idleuntil -999
    # at 450
    # thread 1 - 450 - 400  =  50
    # thread 2 - 450 - 500  = -50
    # thread 3 - 450 - -999 = 1449

    e_threads = self.threads.each_with_index.
      map{|thread,id| [id, thread.idle_until ? self.realtime - thread.idle_until : -999_999_999] }.
      sort_by(&:last).
      reverse

    log("e_threads: #{e_threads.inspect}")
    raise "No valid threads to pass to" if e_threads.empty?

    # if passed thread didn't say how long, leave it at current priority
    self.threads[self.thread_id].idle_until ||= self.realtime if self.threads[self.thread_id]

    self.thread_id = e_threads[0][0]

    self.threads[self.thread_id].idle_until = nil
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
    log "dispatch_instruction - thread #{self.thread_id} @ #{pc} - #{definition.nice} - #{instruction.to_ruby(self.vm).inspect}"
    send("opcode_#{method_name}",ArgWrapper.new(definition,instruction.args))
  end

  def allocate(address,data_type,value = nil)
    log "allocate(address: #{address.inspect}, data_type: #{data_type.inspect}, value: #{value.inspect})"
    raise ArgumentError, "address is nil" unless address
    raise ArgumentError, "data_type is nil" unless data_type
    size = 4

    store_as = { 0x01=>0x01, 0x04=>0x01, 0x05=>0x01,  0x06=>0x06 }[data_type]
    raise ArgumentError, "no store_as entry for data_type #{data_type.inspect}" unless store_as

    to_write = vm.native_to_arg_value(store_as,value)
    raise ArgumentError, "incorrect size #{to_write.inspect}" unless to_write.size == size

    self.allocations[address] = data_type
    write(address,size,to_write)
  end

  def read_as_arg(offset,arg_type,bytes_to_read = nil)
    arg_type = Gta3Vm::Vm::DataTypeMethods::TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)
    bytes_to_read ||= Gta3Vm::Vm::DataTypeMethods.bytes_to_read_for_arg_data_type(arg_type,offset)
    arg = Gta3Vm::Instruction::Arg.new([arg_type,vm.memory.read(offset,bytes_to_read)])
    Gta3Vm::Vm::DataTypeMethods.arg_to_native(arg)
  end

  def write(address,size,to_write)
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
      puts "ArgWrapper: #{args.inspect}"
      if symbol == :var_args
        # exclude last arg, it's just the end-of-list marker
        self.args[0...-1].map{|arg|
          arg = Gta3Vm::Instruction::Arg.new(arg)
          Gta3Vm::Vm::DataTypeMethods.arg_to_native(arg)
        }
      elsif index = definition.args_names.index(symbol)
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

    # used for relative jumps
    attr_accessor :base_offset

    attr_accessor :idle_until

    attr_accessor :is_mission

    def initialize(vm,execution,pc = 0,is_mission = false)
      self.vm = vm
      self.execution = execution
      self.pc = pc
      self.is_mission = is_mission
      if is_mission
        self.base_offset = pc
      end
      self.idle_until = 0
    end

    def sleep(time_to_sleep)
      self.idle_until = self.execution.realtime + time_to_sleep
    end
  end

  # Extra features #######

  require "gta3vm/execution/dirty.rb"
  include Gta3Vm::Execution::Dirty
  
end
