opcode("0004", :SET_VAR_INT, dest:var, value:int ) do
  vars[int:dest] = value
end

opcode("0005", :SET_VAR_FLOAT, dest:var, value:float ) do
  vars[float:dest] = value
end

opcode("0006", :SET_LVAR_INT, dest:lvar, value:int ) do
  locals[int:dest] = value
end

opcode("0008", :ADD_VAL_TO_INT_VAR, dest:var, value:int ) do
  vars[int:dest] = vars[int:dest] + value
end

opcode("000A", :ADD_VAL_TO_INT_LVAR, dest:var, value:int ) do
  locals[int:dest] = locals[int:dest] + value
end

opcode("0058", :ADD_INT_VAR_TO_INT_VAR, dest:var, source:var ) do
  vars[int:dest] = vars[int:dest] + vars[int:source]
end

opcode("005A", :ADD_INT_LVAR_TO_INT_LVAR, dest:var, source:var ) do
  locals[int:dest] = locals[int:dest] + locals[int:source]
end

opcode("0084", :SET_VAR_INT_TO_VAR_INT, dest:var, source:var ) do
  vars[int:dest] = vars[int:source]
end

opcode("0085", :SET_LVAR_INT_TO_LVAR_INT, dest:var, source:var ) do
  locals[int:dest] = locals[int:source]
end

