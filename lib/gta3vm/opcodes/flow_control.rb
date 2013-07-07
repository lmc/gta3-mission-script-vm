opcode("0002", "jump", jump_location:int) do |args|
  if args.jump_location > 0
    self.pc = args.jump_location
  else
    raise "negative jump #{args.jump_location} without base_offset" if !self.threads[self.thread_id].base_offset
    self.pc = self.threads[self.thread_id].base_offset + args.jump_location.abs
  end
end

