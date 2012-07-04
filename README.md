gta3-mission-script-vm
======================

Virtual machine for executing GTA3-engine game mission scripts.

This is a really dumb project because nothing's going to happen without the rest of the game engine/ai but oh well.

```
% irb                                                                                                                                                            130 ↵ ✹ ✭
irb(main):001:0> load "lib/vm.rb"
=> true
irb(main):002:0> Vm.load_scm.controlled_ticks

0 - 02 00 01 20 ab 00 00 73 00 00 00 00 00 00 00 00 00
  opcode: 02 00, args: [["01", "20 ab 00 00"]]
  opcode_0002(:jump_location=>43808)
[end of tick]


43808 - 02 00 01 a4 cf 00 00 00 85 01 00 00 00 00 00 00 00
  opcode: 02 00, args: [["01", "a4 cf 00 00"]]
  opcode_0002(:jump_location=>53156)
[end of tick]


53156 - 02 00 01 d8 d1 00 00 01 62 f6 02 00 57 0b 01 00 87
  opcode: 02 00, args: [["01", "d8 d1 00 00"]]
  opcode_0002(:jump_location=>53720)
[end of tick]


53720 - 02 00 01 8c da 00 00 02 32 89 00 00 4f 00 00 00 50
  opcode: 02 00, args: [["01", "8c da 00 00"]]
  opcode_0002(:jump_location=>55948)
[end of tick]


55948 - 02 00 01 98 da 00 00 03 00 00 00 00 02 00 01 a8 da
  opcode: 02 00, args: [["01", "98 da 00 00"]]
  opcode_0002(:jump_location=>55960)
[end of tick]


55960 - 02 00 01 a8 da 00 00 04 18 ab 00 00 3e 02 00 00 a4
  opcode: 02 00, args: [["01", "a8 da 00 00"]]
  opcode_0002(:jump_location=>55976)
[end of tick]


55976 - a4 03 09 4d 41 49 4e 00 00 00 00 6a 01 04 00 04 00
!!! Exception: Opcode not implemented
VM state:
  #<Vm pc=55978 opcode=[164, 3] opcode_nice="3a4" args=[] stack=[]>
Dump at pc:
55978 - 09 4d 41 49 4e 00 00 00 00 6a 01 04 00 04 00 2c 04
Backtrace:
lib/vm.rb:52:in `tick!'
lib/vm.rb:32:in `controlled_ticks'
(irb):2:in `irb_binding'
```
