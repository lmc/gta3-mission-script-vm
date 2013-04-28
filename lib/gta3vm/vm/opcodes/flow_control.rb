opcode("0002", "jump", jump_location:int) do |args|
  self.pc = args.jump_location
end

