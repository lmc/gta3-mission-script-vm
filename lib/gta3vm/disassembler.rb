# (($: << "./lib") && load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc.disassemble && exit)

class Gta3Vm::Disassembler
  attr_accessor :vm
  attr_accessor :out

  attr_accessor :offsets_to_instructions
  attr_accessor :observed_jumps
  attr_accessor :observed_thread_names

  # AST as hash of memory_address => node(s)
  attr_accessor :ast


  def initialize(vm)
    self.vm = vm
  end

  def disassemble
    self.out = File.open('disassemble.txt','w')  
    self.offsets_to_instructions = Hash.new { |h,k| h[k] = [] }
    self.observed_jumps = []
    self.observed_thread_names = {}
    self.ast = AstNode.new(-1)
    begin
      disassemble_structure
      disassemble_code
      # emit tokens
      # turn jump tokens into labels in 2nd pass
      fuck_with_ast
    ensure
      output_disassembly
      self.out.close
    end
  end

  OPCODES_WITH_JUMPS = {
    [0x02,0x00] => 0,
    [0x4C,0x00] => 0,
    [0x4D,0x00] => 0,
    [0x4F,0x00] => 0,
    [0x50,0x00] => 0,
    [0xD7,0x00] => 0,
  }
  def get_jumps_for_instruction(instruction)
    OPCODES_WITH_JUMPS[instruction.opcode]
  end

  protected

  def fuck_with_ast
    to_scan = [
      ConditionalIfEndAstNode
    ]

    to_scan.each do |scan_klass|

      scanner = AstScanner.new(self,self.ast,0,scan_klass::PATTERN)
      scanner.on_match = lambda do |*|
        # puts "== on_match =="
        # puts scanner.current_match__match_names_to_offsets.inspect
        # node = self.ast[scanner.current_match_start]
        # node.tags(:conditional_if_end__if)
        # node.meta(
        #   block_end: scanner.current_match_end
        # )
        scan_klass.on_match(scanner)

        matches = scanner.current_match__match_names_to_offsets
        self.ast.branch!(matches[:begin][0],matches[:branch_false][0],scan_klass,matches)
      end

      5000.times {
        scanner.think
      }

    end

  end

  # def output_disassembly
  #   self.offsets_to_instructions.keys.sort.each do |offset|
  #     if vm.memory.structure_missions.include?(offset)
  #       self.out.puts ""
  #       self.out.puts ""
  #       self.out.puts ""
  #     end
  #     if observed_jumps.include?(offset)
  #       self.out.puts ""
  #       self.out.puts ":#{emit_label_name(offset,offset)}"
  #     end
  #     self.offsets_to_instructions[offset].each do |declaration|
  #       self.out.puts declaration     
  #     end
  #   end
  # end

  def output_disassembly
    offsets = self.ast.keys.sort
    offsets.each do |offset|
      if offset_has_label?(offset)
        out.puts "\n\n:#{emit_label_name(offset,offset)}"
      end
      output_ast_node(out,offset,self.ast[offset])
    end
  end

  attr_accessor :_indent

  def output_ast_node(out,offset,ast_node)
    ast_node.output(out,self)
  end

  # def output_ast_node(out,offset,ast_node)
  #   self._indent ||= 0
  #   s = ""

  #   if ast_node.size > 0
  #     self._indent += 1

  #     s = ""
  #     s << "#{'  ' * _indent}==== #{ast_node.class.name} ====\n"
  #     ast_node.each_pair do |s_offset,s_node|
  #       s << "#{'  ' * _indent}#{output_ast_node(s_offset,s_node)}\n"
  #     end
  #     s << "#{'  ' * _indent}====\n"

  #     self._indent -= 1

  #   else

  #     if instruction = ast_node.instruction
  #       definition = opcode_definition(instruction)
  #       native_args = instruction.to_ruby(vm)[1]
  #       args = native_args.each_with_index.map{|arg,i| emit_arg( offset, instruction, i, instruction.args[i][0], arg[1] ) }

  #       s << definition.symbol_name.to_s.downcase
  #       if args.present?
  #         s << " " << args.join(" ")
  #       end
  #     end

  #     s << "! #{ast_node.tags.join(' ')} #{ast_node.meta.inspect}"

  #   end

  #   s
  # end

  def offset_has_label?(offset)
    @observed_jumps_sorted ||= self.observed_jumps.sort
    @observed_jumps_sorted.binary_index(offset) != nil
  end

  def disassemble_structure
    offset = 0
    offset += disassemble_instruction_at(offset).size
    # emit_declare(offset, :MEMORY, vm.memory.global_memory_size)
    ast_emit_declare_memory(offset,vm.memory.global_memory_size)

    offset = vm.memory.structure[:memory].end
    offset += disassemble_instruction_at(offset).size
    vm.memory.structure_models.each_with_index do |model,idx|
      # emit_declare(offset, :MODEL, idx,model)
      ast_emit_declare_model(offset,idx,model)
    end

    offset = vm.memory.structure[:models].end
    offset += disassemble_instruction_at(offset).size
    vm.memory.structure_missions.each_with_index do |mission_offset,idx|
      self.observed_jumps << mission_offset
      # emit_declare(offset, :MISSION, idx,"$:#{emit_label_name(mission_offset,mission_offset)}")
      ast_emit_declare_mission(offset,idx,mission_offset)
    end
  end

  def disassemble_code
    offset = vm.memory.structure[:code_main].begin
    # end_offset = vm.memory.structure[:code_missions].try(:end) || vm.memory.structure[:code_main].end
    end_offset = vm.memory.structure[:code_main].end
    while offset < end_offset
      offset += disassemble_instruction_at(offset).size
    end
  end

  def disassemble_instruction_at(offset)
    instruction = vm.instruction_at(offset)
    # emit_instruction(offset,instruction)
    ast_emit_instruction(offset,instruction)
    instruction
  end

  def emit_label_name(offset,instruction_offset)
    # mission_id = get_mission_id_for_offset( offset < 0 ? instruction_offset : offset)
    mission_id = nil
    if offset < 0
      mission_id = get_mission_id_for_offset(instruction_offset)
    elsif vm.memory.structure_missions[0] && offset >= vm.memory.structure_missions[0]
      mission_id = get_mission_id_for_offset(offset)
    end

    if mission_id
      "mission_#{mission_id}_#{get_abs_offset(offset,instruction_offset)}"
    else
      # thread_name = get_thread_name_for_offset(offset) || "main"
      thread_name = "main"
      "#{thread_name}_#{offset}"
    end
  end

  def get_mission_id_for_offset(offset)
    @get_mission_id_for_offset ||= {}
    if @get_mission_id_for_offset.key?(offset)
      @get_mission_id_for_offset[offset]
    else
      @get_mission_id_for_offset[offset] = _get_mission_id_for_offset(offset)
      @get_mission_id_for_offset[offset]
    end
  end

  def _get_mission_id_for_offset(offset)
    if vm.memory.structure_missions[0] && offset >= vm.memory.structure_missions[0]
      (vm.memory.structure_missions + [Float::INFINITY]).each_with_index do |mission_offset,id|
        if offset < mission_offset 
          return id - 1
        end
      end
    end
    nil
  end

  def get_thread_name_for_offset(offset)
    @get_thread_name_for_offset ||= {}
    if @get_thread_name_for_offset.key?(offset)
      @get_thread_name_for_offset[offset]
    else
      @get_thread_name_for_offset[offset] = _get_thread_name_for_offset(offset)
      @get_thread_name_for_offset[offset]
    end
  end

  def _get_thread_name_for_offset(offset)
    sorted_keys = self.observed_thread_names.keys.sort
    sorted_keys.each_with_index do |thread_offset,key_idx|
      if offset <= thread_offset
        key = self.observed_thread_names[ sorted_keys[key_idx - 1] ]
        puts "offset: #{offset} = #{key.inspect}"
        return key
        # puts "#{offset} < #{thread_offset}"
        # puts "key: #{key} - #{self.observed_thread_names[key].inspect}"
        # return self.observed_thread_names[key]
      end
    end
    nil
  end

  def get_abs_offset(offset,instruction_offset)
    if offset < 0
      mission_id = get_mission_id_for_offset(instruction_offset)
      offset = vm.memory.structure_missions[mission_id] + offset.abs
    end
    offset
  end


  # AST emitters

  def ast_emit_declare_memory(offset,memory_size)
    insert_ast_node(offset){ tags(:memory).meta(size: memory_size) }
  end

  def ast_emit_declare_model(offset,index,model_name)
    insert_ast_node(offset){ tags(:model).meta(index: index, model_name: model_name) }
  end

  def ast_emit_declare_mission(offset,index,mission_offset)
    insert_ast_node(offset){ tags(:mission).meta(index: index, mission_offset: mission_offset) }
  end

  def ast_emit_instruction(offset,instruction)
    node = insert_ast_node(offset)
    add_instruction_tag_meta(node,instruction)


    definition = vm.opcodes.definition_for( instruction.opcode )
    native_args = instruction.to_ruby(vm)[1]

    if arg_pos = get_jumps_for_instruction(instruction)
      self.observed_jumps << get_abs_offset(native_args.values[arg_pos],offset)
    end

    if instruction.opcode == [0xA4,0x03] # SCRIPT_NAME
      name = native_args.values[0]
      self.observed_thread_names[offset] = name
    end

  end


  def insert_ast_node(offset,&block)
    # raise "node already exists at #{offset}" if self.ast[offset]
    self.ast[offset] = AstNode.new(offset)
    self.ast[offset].instance_eval(&block) if block_given?
    self.ast[offset]
  end

  def add_instruction_tag_meta(node,instruction)
    node.instruction = instruction
  end


  def opcode_definition(instruction)
    vm.opcodes.definition_for(instruction.opcode)
  end



  def emit_declare(offset,tag,*values)
    self.offsets_to_instructions[offset] << "#{tag} #{values.join(', ')}"
  end

  def emit_instruction(offset,instruction)
    definition = vm.opcodes.definition_for( instruction.opcode )
    native_args = instruction.to_ruby(vm)[1]
    args = native_args.each_with_index.map{|arg,i| emit_arg( offset, instruction, i, instruction.args[i][0], arg[1] ) }

    if arg_pos = get_jumps_for_instruction(instruction)
      self.observed_jumps << get_abs_offset(native_args.values[arg_pos],offset)
    end

    if instruction.opcode == [0xA4,0x03] # SCRIPT_NAME
      name = native_args.values[0]
      self.observed_thread_names[offset] = name
    end

    emit_declare(offset,definition.symbol_name,*args)
  end

  def emit_arg(instruction_offset,instruction,arg_idx,type,value)
    if arg_idx == get_jumps_for_instruction(instruction)
      if value < 0
        "@:#{emit_label_name(value,instruction_offset)}"
      else
        "$:#{emit_label_name(value,instruction_offset)}"
      end
    else
      case vm.type_int_to_shorthand(type)
      when :pg
        "$#{value}"
      when :pl
        "@#{value}"
      else
        value
      end
    end
  end


  class AstNode < Hash
    attr_accessor :address
    attr_accessor :instruction
    attr_accessor :tags
    attr_accessor :meta

    attr_accessor :offset_map

    attr_accessor :parent
    def children; self; end

    def initialize(address,*args)
      self.address = address
      self.tags = []
      self.meta = {}
      super(*args)
    end

    def tags(*array)
      if array.size == 0
        @tags
      else
        array.each { |tag| @tags << tag }
        self
      end
    end

    def meta(hash = {})
      if hash.size == 0
        @meta
      else
        @meta.merge!(hash)
        self
      end
    end

    def inspect
      if self.size == 0
        "#<AstNode {#{self.size}} address: #{@address}, tags: #{@tags.inspect}, meta: #{@meta.inspect}#{' '+inspect_instruction(instruction) if instruction}>"
      else
        super
      end
    end

    def inspect_instruction(instruction)
      instruction.inspect
    end

    def branch!(start_offset,end_offset,klass = self.class,offset_map = nil)
      puts "branch!(#{start_offset.inspect},#{end_offset.inspect})"
      offsets_range = start_offset...end_offset
      offsets = self.keys.sort & offsets_range.to_a # intersection
      puts "  offsets: #{offsets.inspect}"

      new_node = klass.new(offsets[0])

      new_node.offset_map = offset_map if offset_map

      offsets.each do |offset|
        new_node[offset] = self.delete(offset)
      end

      self[offsets[0]] = new_node

      puts "new_node @ #{offsets[0]}: #{new_node.inspect}"
    end


    def self.on_match(scanner)
      puts "== on_match =="
      puts scanner.current_match__match_names_to_offsets.inspect

    end

    def output(out,disassembler)
      if self.size > 0
        output_nested(out,disassembler)
      else
        output_single(out,disassembler)
      end
    end

    def output_nested(out,disassembler)
      out.puts "==#{self.class.name}=="
      self.each_pair { |_,leaf| leaf.output(out,disassembler) }
      out.puts "=="
    end

    def output_single(out,disassembler)
      if instruction = self.instruction
        definition = disassembler.send(:opcode_definition,instruction)
        native_args = instruction.to_ruby(disassembler.vm)[1]
        args = native_args.each_with_index.map{|arg,i| disassembler.send(:emit_arg, self.address, instruction, i, instruction.args[i][0], arg[1] ) }

        s = ""
        s << definition.symbol_name.to_s.downcase
        if args.present?
          s << " " << args.join(" ")
        end

        out.puts s
      end
    end


  end




  class ConditionalIfEndAstNode < AstNode
    PATTERN = [
      [:begin,        :opcode,[0xD6,0x00]], # ANDOR
      [:conditions,   :any],
      [:branch,       :opcode,[0x4D,0x00],{capture_jump: :jump}], # GOTO_IF_FALSE
      [:branch_true,  :any],
      [:branch_false, :offset,:jump]
    ]

    def output_nested(out,disassembler)
      out.puts "#BEGIN"
      super
      out.puts "#END"

      out.puts "IF"
      self.offset_map[:conditions].each do |off|
        self[off].output(out,disassembler) rescue out.puts "!!!"
      end
      # out.puts self.offset_map[:conditions].inspect
      # out.puts self.inspect
      out.puts "THEN"
      # out.puts "-body-"
      self.offset_map[:branch_true].each do |off|
        self[off].output(out,disassembler) rescue out.puts "!!!"
      end
      out.puts "ENDIF"
    end
  end


  class AstScanner
    attr_accessor :disassembler

    attr_accessor :ast
    attr_accessor :ast_idx
    attr_accessor :ast_offsets
    attr_accessor :rules

    attr_accessor :on_match

    attr_accessor :current_match
    attr_accessor :current_match_rule_id
    attr_accessor :current_match_start
    attr_accessor :current_match_end

    attr_accessor :current_match__captured_jumps
    attr_accessor :current_match__match_names_to_offsets

    def initialize(disassembler,ast,ast_idx,rules)
      self.disassembler = disassembler

      self.ast = ast
      self.ast_offsets = self.ast.keys.sort
      self.ast_idx = ast_idx
      self.rules = rules

      self.on_match = lambda { |*| nil }

      record_rule_flunk!
    end

    def current_node
      self.ast[self.ast_offsets[self.ast_idx]]
    end

    def node_idx(idx)
      self.ast[ self.ast_offsets[idx]]
    end

    def current_rule
      self.current_match_rule_id ? self.rules[self.current_match_rule_id] : nil
    end

    def think
      puts
      puts "think  -  idx: #{self.ast_idx},  offset: #{self.ast_offsets[self.ast_idx]}  -  cm_rule_id: #{self.current_match_rule_id}, cm_rule: #{self.current_rule.inspect}"
       # rule_will_match?(current_match_rule_id,ast_idx)

      match, bump, triggers = match_results(current_match_rule_id,ast_idx)
      puts "match, bump, triggers: #{match.inspect}, #{bump.inspect}, #{triggers.inspect}"

      if triggers.size > 0
        puts "  triggers: #{triggers.inspect}"
        triggers.each_pair do |trigger,trigger_args|
          case trigger
          when :record_match
            self.current_match__match_names_to_offsets[trigger_args[1]] ||= []
            self.current_match__match_names_to_offsets[trigger_args[1]] << trigger_args[0]
          when :capture_jump
            self.current_match__captured_jumps ||= {}
            args = current_node.instruction.to_ruby(disassembler.vm)[1]
            puts "    args = #{args.values[0].inspect}"
            self.current_match__captured_jumps[trigger_args] = args.values[0]
          end
        end
      end

      if match
        puts "  match"
        record_rule_match!
      end

      if bump
        puts "  bump"
        self.current_match_rule_id += 1
        if self.current_match_rule_id == self.rules.size
          # fully matched
          puts "  !! MATCH"
          self.current_match_rule_id = 0
          self.current_match_end = self.ast_offsets[self.ast_idx]
          puts "  !! #{self.current_match_start} - #{self.current_match_end}"
          self.on_match.call(self)
        end
      end

      if !match
        puts "  flunk"
        record_rule_flunk!
      end


      self.ast_idx += 1
    end

    def match_results(rule_id,ast_idx)
      node = node_idx(ast_idx)
      rule = self.rules[rule_id]
      puts "rule: #{rule.inspect}"
      puts "node: #{node.inspect}"

      match = nil
      bump = true
      triggers = {record_match: [self.ast_offsets[ast_idx],rule[0]]}

      case rule[1]
      when :opcode
        match = node.instruction ? node.instruction.opcode == rule[2] : false
        options = rule[3] || {}
        if match && options[:capture_jump]
          triggers[:capture_jump] = options[:capture_jump]
        end
      when :any
        # if the next node will match the next rule,
        n_match, n_bump, n_triggers = match_results(rule_id + 1, ast_idx + 1)
        puts "n_match, n_bump, n_triggers: #{n_match.inspect}, #{n_bump.inspect}, #{n_triggers.inspect}"
        if n_match
          # bump rule_id for next match
          match = true
        else
          # otherwise tell it that we matched, but we're gonna try to match some more
          match = true
          bump = false
        end
      when :offset
        puts "    - #{self.current_match__captured_jumps.inspect}"
        puts "    - #{node.address} == #{self.current_match__captured_jumps[rule[2]]}"
        match = node.address == self.current_match__captured_jumps[rule[2]]
      end

      [match,bump,triggers]
    end

    protected

    def record_rule_match!
      if !self.current_match
        self.current_match_start = self.ast_offsets[self.ast_idx]
      end
      self.current_match = true
    end

    def record_rule_flunk!
      self.current_match = false
      self.current_match_rule_id = 0

      self.current_match__captured_jumps = {}
      self.current_match__match_names_to_offsets = {}
    end


  end

end
