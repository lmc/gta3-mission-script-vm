opcode("0004", :SET_VAR_INT, out:pg, value:int ) do |args|
  variables[args.out] = args.value_type, args.value
end

opcode("0005", :SET_VAR_FLOAT, out:pg, value:float ) do |args|
  variables[args.out] = args.value_type, args.value
end

opcode("0006", :SET_LVAR_INT, out:lg, value:int ) do |args|
  locals[args.out] = :int32, args.value
end

opcode("0007", :SET_LVAR_FLOAT, out:lg, value:float ) do |args|
  locals[args.out] = :float32, args.value
end

opcode("0008", :ADD_VAL_TO_INT_VAR, out:pg, value:int ) do |args|
  variables[args.out] = :int32, variables[args.out,:int32] + args.value
end

opcode("04AE", "set_global_int_or_float", out:pg, value:int_or_float ) do |args|
  variables[args.out] = args.value_type, args.value
end

opcode("0058", :ADD_INT_VAR_TO_INT_VAR, out:pg, to_add:pg ) do |args|
  value  = variables[args.out,    :int32]
  value += variables[args.to_add, :int32]
  variables[args.out] = :int32, value
end

opcode("0084", :SET_VAR_INT_TO_VAR_INT, out:pg, in:pg ) do |args|
  variables[args.out] = :int32, variables[args.in, :int32]
end

