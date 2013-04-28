opcode("03A4", "thread_set_name", thread_name:string) do |args|
  self.thread_names[self.thread_id] = args.thread_name
end

