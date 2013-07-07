opcode("0001", "wait", min_ms:int) do |args|
  self.threads[self.thread_id].sleep(args.min_ms)
  self.thread_pass
end

opcode("03A4", "thread_set_name", thread_name:string) do |args|
  self.threads[self.thread_id].name = args.thread_name
end

opcode("0417", "start_mission", mission_id:int) do |args|
  # MAIN size, largest mission size, number of missions, then the list of mission offsets
  mission_offset_at = vm.memory.structure[:missions].begin + 4 + 4 + 4 + (args.mission_id * 4)
  offset = self.read_as_arg(mission_offset_at,:int32)
  self.thread_create(offset,true)
end

opcode("004E", "thread_end") do |args|
  self.threads[self.thread_id].idle_until = 999_999_999
  self.thread_pass
  # TODO: prevent automatic PC advance? does this make sense?
end

opcode("004F", "thread_create_with_args", var_args:int) do |args|
  self.thread_create( args.var_args[0] )
  # TODO: assign rest of var_args to thread vars
  raise "unassigned thread vars" if args.var_args.length > 1
end


