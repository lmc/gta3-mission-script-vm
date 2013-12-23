opcode("0001", :WAIT, ms:int) do
  thread_idle( realtime + ms )
end

opcode("03A4", "thread_set_name", thread_name:string) do
  current_thread.name = thread_name
end

# opcode("0417", "start_mission", mission_id:int) do |args|
#   thread_create( vm.memory.structure_missions[mission_id], true )
# end

opcode("004E", "thread_end") do
  thread_idle( 999_999_999 )
  # TODO: prevent automatic PC advance? does this make sense?
end

opcode("004F", "thread_create_with_args", var_args:int) do
  thread_create( var_args[0] )
  # TODO: assign rest of var_args to thread vars
  assert( var_args.length == 1, "unassigned thread vars" )
end


