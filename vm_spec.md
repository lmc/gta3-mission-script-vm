## The GTA3-era Script VM

The GTA3-era games all have an embedded VM for running high-level game code. Essential gameplay elements like controls, physics, AI, etc. are handled by the engine itself, but almost everything else is run through the script VM. This includes initial world setup, cutscenes and interactive features, and all the missions and minigames.

The VM is a Von Neumann architecture, with working memory and executable code sharing a common block of memory. While variable values are stored within the shared memory space, other elements like the program counter, stacks, etc. are not addressable.

Threads are implemented with a basic cooperative multitasking scheme, changing threads whenever the current one reaches a `sleep` instruction. This is somewhat fragile, the original games will crash if too many instructions are executed without changing threads.

The VM executes instructions from bytecode stored in .SCM files. Each instruction contains a 2-byte opcode, and then an opcode-specific number of arguments. Each argument starts with a 1-byte type ID, then the argument value. Some opcodes and data types allow for variable-length arguments or values, which complicates parsing.

While none of the original games use this, the VM is capable of self-modifying code and other low-level tricks. In addition, bugs in some opcode handlers allow for reading or writing to arbitary addresses within the game process itself, allowing code to "escape" from the VM.


## SCM file format

In the original games, the SCM files all follow a common format of several special blocks of binary data, with the real bytecode starting later. Each block has a 1-byte ID and is proceded by a `jump` opcode that allows execution to skip over it.

The blocks are as follows:

0x6D - Memory
This block is used for global variable storage, and is filled with null bytes.

0x00 - Models
This block has a table of IDs to string model names, used with certain opcodes that create or manipulate 3D models in-game.

0x00 - Mission offsets
This block has a table of IDS to bytecode offsets, used to start executing missions. Missions run inside a special type of thread, with several 'magic features', to be covered later.


Following these blocks, the bytecode begins. The original games follow a convention of having a bootstrapped MAIN thread that does the following:

* Initialize the world and player
* Start 'mission 0', which sets many global variables and world features like parked car generators, weapon pickups, etc.
* Once complete, start 'mission 1', which starts the game's opening cutscene, which creates other 'mission listener' threads at the end.
* Puts MAIN into an idle loop.

## Threads

### Mission Threads





## Observed Coding Conventions

### Loading loops

### Mission listener threads



