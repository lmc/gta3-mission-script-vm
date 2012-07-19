gta3-mission-script-vm
======================

Virtual machine for executing GTA3-engine game mission scripts.

This is a really dumb project because nothing's going to happen without the rest of the game engine/ai but oh well.

Rack frontend

Addresses as arguments highlight their values in the memory editor.

![Rack frontend](http://i.imgur.com/nDb7p.png)


Colour screenshot of it running, you can see it highlighting symbols in the bytecode.
green = opcode, pink = data type, blue = actual value bytes
It also colours allocations in memory, seen on the lines starting with ooooooo8.

![Coloured VM output](http://i.imgur.com/vcM7B.png)

Basic cooperative multi-tasking

![Basic cooperative multi-tasking](http://i.imgur.com/dD9lj.png)

Does really ugly branching

![Really ugly branching](http://i.imgur.com/dbzjS.png)


```
% irb
irb(main):001:0> (load("lib/vm.rb") && Vm.load_scm("main").run)

```

TODO:

Refactor JS (possibly backbone later)
Google Maps/WebGL map viewer
  Draw opcode arguments
  Draw game objects
  Draw things from game data files
Nicer thread/current instruction view
  Disassembly around PC
  Local thread variables
  Show current thread only, can scroll/expand horizontally for others

Panels
  VM state/stats
    Tick once/more
    Update game time normal/more/less (1 tick = 1ms?)
    View/edit conditions
  Game state
    Render positions
    Game time
    World time
    Screen/camera state
    Current mission
  Threads
  Memory
  Game objects
  Map
