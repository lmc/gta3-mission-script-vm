gta3-mission-script-vm
======================

Virtual machine for executing GTA3-engine game mission scripts.

This is a really dumb project because nothing's going to happen without the rest of the game engine/ai but oh well.

Colour screenshot of it running, you can see it highlighting symbols in the bytecode.
green = opcode, pink = data type, blue = actual value bytes
It also colours allocations in memory, seen on the lines starting with ooooooo8.

![Coloured VM output](http://i.imgur.com/vcM7B.png)

Basic cooperative multi-tasking

![Basic cooperative multi-tasking](http://i.imgur.com/dD9lj.png)


```
% irb                                                                                                                         ✚
irb(main):001:0> (load("lib/vm.rb") && Vm.load_scm("main").run)

```
