module Opcodes
  class << self
    attr_accessor :definitions
  end
  self.definitions = {}
  include OpcodeDsl

  opcode("0002", "jump", :jump_location => :int) do |args|
    self.pc = args.jump_location.value_native
  end

  opcode("03A4", "thread_set_name", :thread_name => :string) do |args|
    self.thread_names[self.thread_id] = args.thread_name.value_native
  end

  opcode("016A", "screen_fade", :fade_in_out => :bool, :fade_time => :int) do |args|
    # do nothing?
  end

  opcode("042C", "engine_set_missions_count", :missions_count => :int) do |args|
    self.missions_count = args.missions_count.value_native
  end

  opcode("030D", "engine_set_progress_count", :progress_count => :int) do |args|
    self.progress_count = args.progress_count.value_native
  end
end
