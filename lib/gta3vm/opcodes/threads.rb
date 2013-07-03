opcode("03A4", "thread_set_name", thread_name:string) do |args|
  self.threads[self.thread_id].name = args.thread_name
end

