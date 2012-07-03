gta3-mission-script-vm
======================

Virtual machine for executing GTA3-engine game mission scripts.

This is a really dumb project because nothing's going to happen without the rest of the game engine/ai but oh well.

```
irb

irb(main):030:0> Vm.load_scm
0 - 02 00 01 20 ab 00 00 73 00 00 00 00 00 00 00 00 00
  opcode 02 00 args: [[1, [32, 171, 0, 0]]]
found jump to 43808?
43808 - 02 00 01 a4 cf 00 00 00 85 01 00 00 00 00 00 00 00
[end of tick]

43808 - 02 00 01 a4 cf 00 00 00 85 01 00 00 00 00 00 00 00
  opcode 02 00 args: [[1, [164, 207, 0, 0]]]
found jump to 53156?
53156 - 02 00 01 d8 d1 00 00 01 62 f6 02 00 57 0b 01 00 87
[end of tick]

53156 - 02 00 01 d8 d1 00 00 01 62 f6 02 00 57 0b 01 00 87
  opcode 02 00 args: [[1, [216, 209, 0, 0]]]
found jump to 53720?
53720 - 02 00 01 8c da 00 00 02 32 89 00 00 4f 00 00 00 50
[end of tick]

=> pc: 53720
```
