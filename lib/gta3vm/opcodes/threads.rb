opcode("0001", :WAIT, min_ms:int) do |args|
  thread_idle( realtime + args.min_ms )
end

opcode("03A4", "thread_set_name", thread_name:string) do |args|
  current_thread.name = args.thread_name
end

opcode("0417", "start_mission", mission_id:int) do |args|
  thread_create( vm.memory.structure_missions[args.mission_id], true )
end

opcode("004E", "thread_end") do |args|
  thread_idle( 999_999_999 )
  # TODO: prevent automatic PC advance? does this make sense?
end

opcode("004F", "thread_create_with_args", var_args:int) do |args|
  thread_create( args.var_args[0] )
  args_count = args.var_args.length - 1
  args_count -= 1 if args.var_args[-1] == [0]
  puts "thread_create_with_args: #{args.var_args.length} #{args_count}"
  # TODO: assign rest of var_args to thread vars
  assert( args_count < 1, "unassigned thread vars" )
end


