opcode("03A4", "thread_set_name", thread_name:string) do |args|
  self.threads[self.thread_id].name = args.thread_name
end

opcode("0417", "start_mission", mission_id:int) do |args|
  mission_offset_at = vm.memory.structure[:missions].begin + (args.mission_id * 4)
  offset = self.read_as_arg(mission_offset_at,:int32)
  self.create_thread(offset,true)
end


