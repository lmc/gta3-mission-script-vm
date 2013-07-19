opcode("0004", "set_global_int", out:pg, value:int ) do |args|
  variables[args.out] = args.value_type, args.value
end

opcode("0005", "set_global_float", out:pg, value:float ) do |args|
  variables[args.out] = args.value_type, args.value
end

opcode("04AE", "set_global_int_or_float", out:pg, value:int_or_float ) do |args|
  variables[args.out] = args.value_type, args.value
end

opcode("0008", "add_set_global_int", out:pg, value:int ) do |args|
  variables[args.out] = :int32, variables[args.out,:int32] + args.value
end