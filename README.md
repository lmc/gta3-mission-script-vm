gta3-mission-script-vm
======================

Virtual machine for executing GTA3-engine game mission scripts.

This is a really dumb project because nothing's going to happen without the rest of the game engine/ai but oh well.

Colour screenshot of it running, you can see it highlighting symbols in the bytecode.
green = opcode, pink = data type, blue = actual value bytes


![Coloured VM output](http://i.imgur.com/3z3wl.png)


```
% irb
irb(main):001:0> load "lib/vm.rb"
=> true
irb(main):002:0> Vm.load_scm.run
ooooooo0 - 02 00 01 20 ab 00 00 73 00 00 00 00 00 00 00 00 00
           02 00 01 20 ab 00 00
  opcode_0002_jump(:jump_location=>43808)
[end of tick]

ooo43808 - 02 00 01 a4 cf 00 00 00 85 01 00 00 00 00 00 00 00
           02 00 01 a4 cf 00 00
  opcode_0002_jump(:jump_location=>53156)
[end of tick]

ooo53156 - 02 00 01 d8 d1 00 00 01 62 f6 02 00 57 0b 01 00 87
           02 00 01 d8 d1 00 00
  opcode_0002_jump(:jump_location=>53720)
[end of tick]

ooo53720 - 02 00 01 8c da 00 00 02 32 89 00 00 4f 00 00 00 50
           02 00 01 8c da 00 00
  opcode_0002_jump(:jump_location=>55948)
[end of tick]

ooo55948 - 02 00 01 98 da 00 00 03 00 00 00 00 02 00 01 a8 da
           02 00 01 98 da 00 00
  opcode_0002_jump(:jump_location=>55960)
[end of tick]

ooo55960 - 02 00 01 a8 da 00 00 04 18 ab 00 00 3e 02 00 00 a4
           02 00 01 a8 da 00 00
  opcode_0002_jump(:jump_location=>55976)
[end of tick]

ooo55976 - a4 03 09 4d 41 49 4e 00 00 00 00 6a 01 04 00 04 00
           a4 03 09 4d 41 49 4e 00 00 00 00
  opcode_03A4_thread_set_name(:thread_name=>"MAIN")
[end of tick]

ooo55987 - 6a 01 04 00 04 00 2c 04 05 93 00 0d 03 05 bb 00 97
           6a 01 04 00 04 00
  opcode_016A_screen_fade(:fade_in_out=>0,:fade_time=>0)
[end of tick]

ooo55993 - 2c 04 05 93 00 0d 03 05 bb 00 97 09 05 3b 05 f0 01
           2c 04 05 93 00
  opcode_042C_engine_set_missions_count(:missions_count=>147)
[end of tick]

ooo55998 - 0d 03 05 bb 00 97 09 05 3b 05 f0 01 04 06 11 01 04
           0d 03 05 bb 00
  opcode_030D_engine_set_progress_count(:progress_count=>187)
[end of tick]

ooo56003 - 97 09 05 3b 05 f0 01 04 06 11 01 04 00 c0 00 04 08

!!! Vm::InvalidOpcode: 0997 not implemented
VM state:
#<Vm pc=56005 thread_id=0 thread_name="MAIN" opcode=[151, 9] opcode_nice="0997" args=[[5, [187, 0]]] stack=[]>

Dump at pc:
ooo56005 - 05 3b 05 f0 01 04 06 11 01 04 00 c0 00 04 08 04 00

Backtrace:
lib/vm.rb:78:in `tick!'
lib/vm.rb:59:in `run'
```
