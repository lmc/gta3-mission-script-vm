gta3-mission-script-vm
======================

Virtual machine for executing GTA3-engine game mission scripts.

This is a really dumb project because nothing's going to happen without the rest of the game engine/ai but oh well.

Colour screenshot of it running, you can see it highlighting symbols in the bytecode.
green = opcode, pink = data type, blue = actual value bytes
It also colours allocations in memory, seen on the lines starting with ooooooo8.

![Coloured VM output](http://i.imgur.com/vcM7B.png)


```
% irb                                                                                                                         ✚
irb(main):001:0> (load("lib/vm.rb") && Vm.load_scm("main").run)
ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooooooo0 - 02 00 01 20 ab 00 00 73 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
           02 00 01 20 ab 00 00
  opcode_0002_jump(:jump_location=>43808)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo43808 - 02 00 01 a4 cf 00 00 00 85 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
           02 00 01 a4 cf 00 00
  opcode_0002_jump(:jump_location=>53156)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo53156 - 02 00 01 d8 d1 00 00 01 62 f6 02 00 57 0b 01 00 87 00 00 00 c4 03 00 00 62 f6 02 00 c8 d9 03 00 
           02 00 01 d8 d1 00 00
  opcode_0002_jump(:jump_location=>53720)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo53720 - 02 00 01 8c da 00 00 02 32 89 00 00 4f 00 00 00 50 4c 41 59 45 52 5f 50 41 52 41 43 48 55 54 45 
           02 00 01 8c da 00 00
  opcode_0002_jump(:jump_location=>55948)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo55948 - 02 00 01 98 da 00 00 03 00 00 00 00 02 00 01 a8 da 00 00 04 18 ab 00 00 3e 02 00 00 a4 03 09 4d 
           02 00 01 98 da 00 00
  opcode_0002_jump(:jump_location=>55960)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo55960 - 02 00 01 a8 da 00 00 04 18 ab 00 00 3e 02 00 00 a4 03 09 4d 41 49 4e 00 00 00 00 6a 01 04 00 04 
           02 00 01 a8 da 00 00
  opcode_0002_jump(:jump_location=>55976)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo55976 - a4 03 09 4d 41 49 4e 00 00 00 00 6a 01 04 00 04 00 2c 04 05 93 00 0d 03 05 bb 00 97 09 05 3b 05 
           a4 03 09 4d 41 49 4e 00 00 00 00
  opcode_03A4_thread_set_name(:thread_name=>"MAIN")
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo55987 - 6a 01 04 00 04 00 2c 04 05 93 00 0d 03 05 bb 00 97 09 05 3b 05 f0 01 04 06 11 01 04 00 c0 00 04 
           6a 01 04 00 04 00
  opcode_016A_screen_fade(:fade_in_out=>0,:fade_time=>0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo55993 - 2c 04 05 93 00 0d 03 05 bb 00 97 09 05 3b 05 f0 01 04 06 11 01 04 00 c0 00 04 08 04 00 e4 04 06 
           2c 04 05 93 00
  opcode_042C_engine_set_missions_count(:missions_count=>147)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo55998 - 0d 03 05 bb 00 97 09 05 3b 05 f0 01 04 06 11 01 04 00 c0 00 04 08 04 00 e4 04 06 ff 88 1b 45 06 
           0d 03 05 bb 00
  opcode_030D_engine_set_progress_count(:progress_count=>187)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56003 - 97 09 05 3b 05 f0 01 04 06 11 01 04 00 c0 00 04 08 04 00 e4 04 06 ff 88 1b 45 06 aa 5b d0 c4 cb 
           97 09 05 3b 05
  opcode_0997_engine_set_respect_count(:respect_count=>1339)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56008 - f0 01 04 06 11 01 04 00 c0 00 04 08 04 00 e4 04 06 ff 88 1b 45 06 aa 5b d0 c4 cb 03 06 ff 88 1b 
           f0 01 04 06
  opcode_01F0_engine_set_max_wanted_level(:max_wanted_level=>6)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56012 - 11 01 04 00 c0 00 04 08 04 00 e4 04 06 ff 88 1b 45 06 aa 5b d0 c4 cb 03 06 ff 88 1b 45 06 aa 5b 
           11 01 04 00
  opcode_0111_engine_set_wasted_busted_check(:wasted_busted_check=>0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56016 - c0 00 04 08 04 00 e4 04 06 ff 88 1b 45 06 aa 5b d0 c4 cb 03 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 
           c0 00 04 08 04 00
  opcode_00C0_engine_set_game_time(:hour=>8,:minute=>0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56022 - e4 04 06 ff 88 1b 45 06 aa 5b d0 c4 cb 03 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 56 41 2a 06 05 
           e4 04 06 ff 88 1b 45 06 aa 5b d0 c4
  opcode_04E4_engine_refresh_renderer_at(:x=>2488.562255859375,:y=>-1666.864501953125)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56034 - cb 03 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 56 41 2a 06 05 a5 00 06 00 00 48 44 2a 06 04 17 06 
           cb 03 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 56 41
  opcode_03CB_engine_set_renderer_at(:x=>2488.562255859375,:y=>-1666.864501953125,:z=>13.375699996948242)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56051 - 2a 06 05 a5 00 06 00 00 48 44 2a 06 04 17 06 00 00 48 42 2a 06 04 15 06 00 00 48 43 2a 06 05 a0 
           2a 06 05 a5 00 06 00 00 48 44
  opcode_062A_engine_set_game_stat_float(:var_id=>165,:value=>800.0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56061 - 2a 06 04 17 06 00 00 48 42 2a 06 04 15 06 00 00 48 43 2a 06 05 a0 00 06 00 00 00 00 29 06 05 b5 
           2a 06 04 17 06 00 00 48 42
  opcode_062A_engine_set_game_stat_float(:var_id=>23,:value=>50.0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56070 - 2a 06 04 15 06 00 00 48 43 2a 06 05 a0 00 06 00 00 00 00 29 06 05 b5 00 04 00 29 06 04 44 04 00 
           2a 06 04 15 06 00 00 48 43
  opcode_062A_engine_set_game_stat_float(:var_id=>21,:value=>200.0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56079 - 2a 06 05 a0 00 06 00 00 00 00 29 06 05 b5 00 04 00 29 06 04 44 04 00 53 00 04 00 06 ff 88 1b 45 
           2a 06 05 a0 00 06 00 00 00 00
  opcode_062A_engine_set_game_stat_float(:var_id=>160,:value=>0.0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56089 - 29 06 05 b5 00 04 00 29 06 04 44 04 00 53 00 04 00 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 4e 41 
           29 06 05 b5 00 04 00
  opcode_0629_engine_set_game_stat_int(:var_id=>181,:value=>0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56096 - 29 06 04 44 04 00 53 00 04 00 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 4e 41 02 08 00 02 00 01 59 
           29 06 04 44 04 00
  opcode_0629_engine_set_game_stat_int(:var_id=>68,:value=>0)
[end of tick]

ooooooo8 - 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56102 - 53 00 04 00 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 4e 41 02 08 00 02 00 01 59 db 00 00 53 00 04 
           53 00 04 00 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 4e 41 02 08 00
  opcode_0053_player_create(:model=>0,:x=>2488.562255859375,:y=>-1666.864501953125,:z=>12.875699996948242,:player_id=>8)
[end of tick]

ooooooo8 - 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56124 - 02 00 01 59 db 00 00 53 00 04 01 06 ff 88 1b 45 06 aa 5b d0 c4 06 de 02 4e 41 02 6c 02 cf 06 04 
           02 00 01 59 db 00 00
  opcode_0002_jump(:jump_location=>56153)
[end of tick]

ooooooo8 - 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
ooo56153 - cf 06 04 00 46 07 04 01 04 08 04 00 46 07 04 04 04 08 04 07 46 07 04 03 04 08 04 09 46 07 04 03 

!!! Vm::InvalidOpcode: 06CF not implemented
VM state:
#<Vm pc=56155 thread_id=0 thread_name="MAIN" opcode=[207, 6] opcode_nice="06CF" args=[] stack=[] thread_names=["MAIN"] engine_vars=#<OpenStruct progress_count=187, respect_count=1339, max_wanted_level=6, wasted_busted_check=0, time_hour=8, time_minute=0, game_stats={165=>800.0, 23=>50.0, 21=>200.0, 160=>0.0, 181=>0, 68=>0}> allocations={8=>[:pg_if, 1]} allocation_ids={:pg_if=>1} missions_count=147>

Dump at pc:
ooo56155 - 04 00 46 07 04 01 04 08 04 00 46 07 04 04 04 08 

Backtrace:
lib/vm.rb:107:in `tick!'
lib/vm.rb:73:in `run'

```
