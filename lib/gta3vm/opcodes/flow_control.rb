opcode("0002", :GOTO, goto:int) do
  if goto >= 0
    jump( goto )
  else
    assert( current_thread.base_offset, "negative jump #{goto} without base_offset" )
    jump( current_thread.base_offset + goto.abs )
  end
end

