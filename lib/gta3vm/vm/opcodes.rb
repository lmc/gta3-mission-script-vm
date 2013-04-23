class Gta3Vm::Opcodes

  attr_accessor :vm
  attr_accessor :opcode_data
  attr_accessor :opcode_module

  def initialize(vm)
    self.vm = vm
    self.opcode_data = {}
    self.opcode_module = Module.new
    load_opcode_definitions
  end

  def load_opcode_definitions
    Dir.glob("lib/gta3vm/vm/opcodes/*.rb").each do |path|
      int, float, bool, string = :int, :float, :bool, :string
      pg = :pg
      int_or_float, int_or_var, float_or_var = :int_or_float, :int_or_var, :float_or_var
      eval(File.read(path))
    end
  end

  def valid?(opcode)
    !!self.opcode_data[opcode]
  end

  def definition_for(opcode)
    opcode = undo_negated_opcode(opcode)
    self.opcode_data[opcode]
  end

  # Conditional opcodes can have the highest bit of the opcode set to 1
  # So they look like 8038 instead of 0038
  # This is basically a NOT version of the normal opcode
  # We should detect this here, set a flag to say the next write_branch_condition call
  # should be negated, and remove the high bit on the opcode so it calls the "plain" opcode
  NEGATED_OPCODE_MASK = 0x80
  def undo_negated_opcode(opcode)
    good_opcode = opcode
    good_opcode[1] -= NEGATED_OPCODE_MASK if good_opcode[1] >= NEGATED_OPCODE_MASK
    good_opcode
  end

  # dsl method
  def opcode(opcode_name_string,sym_name,arguments_definition = {},&block)
    opcode_bytes = opcode_name_string.scan(/(..)/).map{|hex| hex[0].to_i(16) }.reverse
    self.opcode_data[opcode_bytes] = Gta3Vm::OpcodeDefinition.new({
      :sym_name   => sym_name,
      :nice       => opcode_name_string,
      :args_count => arguments_definition.size,
      :args_names => arguments_definition.keys,
      :args_types => arguments_definition.values.map { |type| type }
    })
    self.opcode_module.class_eval do
      define_method("opcode_#{opcode_name_string}",&block)
    end
  end

end
