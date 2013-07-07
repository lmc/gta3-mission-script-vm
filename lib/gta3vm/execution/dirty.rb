module Gta3Vm::Execution::Dirty
  extend ActiveSupport::Concern

  included do
    attr_accessor :dirty_memory
    alias_method_chain :tick, :dirty
    alias_method_chain :write, :dirty
  end

  module InstanceMethods

    DIRTY_MEMORY_INITIAL = 36 * 1024
    def tick_with_dirty
      @dirty_memory = []
      # mark all memory as dirty on first tick
      dirty_memory_mark(0,vm.memory.size) if tick_count == 0
      # dirty_memory_mark(0,DIRTY_MEMORY_INITIAL) if tick_count == 0
      tick_without_dirty
    end

    def write_with_dirty(address,size,to_write)
      write_without_dirty(address,size,to_write)
      dirty_memory_mark(address,size)
    end

    def dirty_memory_mark(address,size)
      # puts "dirty_memory_mark(#{[address,size].inspect})"
      @dirty_memory << [address,size,vm.memory.read(address,size)]
    end

  end
  
end
