module OpcodeDsl
  def self.included(base)
    base.class_eval do
      
      # NOTE: arguments_definition is ruby 1.9 only, due to the need for ordered hashes
      def self.opcode(sym_name,opcode_name_string,arguments_definition = {},&block)
        opcode_bytes = opcode_name_string.scan(/(..)/).map{|hex| hex[0].to_i(16) }.reverse
        self.definitions[opcode_bytes] = {
          :sym_name   => sym_name,
          :nice       => opcode_name_string,
          :args_count => arguments_definition.size,
          :args_names => arguments_definition.keys,
          :args_types => arguments_definition.values.map { |type| TYPE_SHORTHANDS[type] }
        }
        define_method("opcode_#{opcode_name_string}",&block)
      end

    end
  end
end
