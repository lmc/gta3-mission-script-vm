opcode("0004", "set_global_int", ret_address:pg, value:int ) do |args|
  allocate(args.ret_address,args.value_type,args.value)
end

opcode("0005", "set_global_float", ret_address:pg, value:float ) do |args|
  puts [args.ret_address,args.value_type,args.value].inspect
  allocate!(args.ret_address,args.value_type,args.value)
end

opcode("04AE", "set_global_int_or_float", ret_address:pg, value:int_or_float ) do |args|
  allocate!(args.ret_address,args.value_type,args.value)
end

opcode("0008", "add_set_global_int", ret_address:pg, value:int ) do |args|
  gv_value = arg_to_native(:int32,read(args.ret_address,4))
  gv_value += args.value 
  allocate!(args.ret_address,:int32,gv_value)
end