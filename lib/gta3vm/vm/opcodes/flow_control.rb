opcode("0002", "jump", jump_location:int) do |args|
  self.pc = args.jump_location
end

opcode("03A4", "thread_set_name", thread_name:string) do |args|
  self.thread_names[self.thread_id] = args.thread_name
end