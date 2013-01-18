module OpcodeDsl
  def self.included(base)
    base.class_eval do
      
      # NOTE: arguments_definition is ruby 1.9 only, due to the need for ordered hashes
      def self.opcode(opcode_name_string,sym_name,arguments_definition = {},&block)
        opcode_bytes = opcode_name_string.scan(/(..)/).map{|hex| hex[0].to_i(16) }.reverse
        self.definitions[opcode_bytes] = {
          :sym_name   => sym_name,
          :nice       => opcode_name_string,
          :args_count => arguments_definition.size,
          :args_names => arguments_definition.keys,
          :args_types => arguments_definition.values.map { |type| type }
        }
        define_method("opcode_#{opcode_name_string}",&block)
      end

      def self.parse_from_scm_ini(path_to_ini)
        File.open(path_to_ini,"r").read.each_line do |line|
          next unless line =~ /\A([0-9a-f]{4})\=(\d+),(.*)?/i
          opcode, arg_count, notes = $1.upcase, $2.to_i, $3

          # try to hack something nice out of the notes
          notes = notes.gsub(/(%.*?%)/im,'').strip.gsub(/;/,'').gsub(/\s+/,'_')
          opcode_name = "#{opcode}_#{notes}"
          puts opcode_name
          
          args_def = {}
          arg_count.times{ |i| args_def["arg_#{i}"] = -1 }
          opcode(opcode,"auto_#{opcode_name}",args_def) { |args|
            puts "  !!! WARNING: opcode #{opcode} is auto-generated and NOOP"
          }
        end
      end

      def self.engine_var_setter(engine_var_name)
        lambda { |args| self.engine_vars.send("#{engine_var_name}=", args.send(engine_var_name)) }
      end

    end
  end
end
