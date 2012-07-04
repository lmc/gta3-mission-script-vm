module Opcodes
  class << self
    attr_accessor :definitions
  end
  self.definitions = {}
  include OpcodeDsl

  opcode(:jump, "0002", :jump_location => :int32) do |args|
    self.pc = args.jump_location.value_native
  end
end