opcode("0002", :GOTO, goto:int) do |args|
  if args.goto >= 0
    jump( args.goto )
  else
    assert( current_thread.base_offset, "negative jump #{args.goto} without base_offset" )
    jump( current_thread.base_offset + args.goto.abs )
  end
end

