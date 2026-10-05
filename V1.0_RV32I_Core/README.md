# RV32I Pipelined CPU

A 32-bit RISC-V CPU, written from scratch in Verilog using a classic 5-stage pipeline.

## Table of Contents
+ [About](#about)
+ [Features](#features)
+ [Project Structure](#project_structure)
+ [Getting Started](#getting_started)
+ [Usage](#usage)
+ [Design Overview](#design_overview)
+ [Limitations](#limitations)
+ [Future Work](#future_work)

## About <a name = "about"></a>

This project is a working RISC-V CPU core written in Verilog.

The CPU currently implements the RV32I base integer instruction set, the base set of RISC-V instructions. It uses a 5-stage pipeline, which means up to five instructions are in flight at the same time, each at a different stage of execution. The design also handles tricky cases such as when one instruction needs the result of another that has not finished yet, the CPU either forwards the value directly or briefly pauses the pipeline to wait.


## Features <a name = "features"></a>

- RV32I base integer instruction set (no extensions yet)
- 5-stage pipeline: Fetch, Decode, Execute, Memory, Writeback
- Full forwarding from the Execute/Memory and Memory/Writeback pipeline registers
- Load-use hazard detection with a one-cycle stall
- Branch and jump resolution in the Execute stage with pipeline flush
- Predict-not-taken branch prediction
- Little-endian, byte-addressable data memory with byte, halfword, and word access
- Written in Verilog
- Simulated with Icarus Verilog alongside gtkwave

## Project Structure <a name = "project_structure"></a>

```
rtl/         Verilog source for every module
  definitions.vh    Global macros (opcodes, ALU ops, immediate types, etc.)
  top.v             The top-level CPU: instantiates everything and wires it together
  pc.v              Program counter
  imem.v            Instruction memory (read-only, loaded from a hex file)
  dmem.v            Data memory (read/write, byte-addressable)
  if_id.v           Pipeline register between Fetch and Decode
  id_ex.v           Pipeline register between Decode and Execute
  ex_mem.v          Pipeline register between Execute and Memory
  mem_wb.v          Pipeline register between Memory and Writeback
  decoder.v         Instruction decoder
  register.v        Register file (32 registers, x0 hardwired to zero)
  immgen.v          Immediate generator
  alu.v             Arithmetic logic unit
  forward.v         Forwarding unit
  hazard.v          Hazard detection unit
  branch.v          Branch decision unit

tb/          Testbenches, one per module plus the full CPU
programs/    Test programs in hex format, one instruction per line
```

## Getting Started <a name = "getting_started"></a>

These instructions will get the project running on your own computer so you can simulate the CPU and watch it execute programs.

### Prerequisites

You need three tools:

- **Icarus Verilog:** compiles and runs the Verilog code.
- **GTKWave:** views waveform dumps.

On Debian based systems:

```bash
sudo apt install iverilog gtkwave
```

To check that Icarus Verilog is installed:

```bash
iverilog -V
```

You should see a version number.

### Installing

Clone the repository:

```bash
git clone https://github.com/IKen24/RiscV_Verilog.git
cd RiscV_Verilog
```

Create a folder for simulation output:

```bash
mkdir -p sim
```

That is it. There is nothing to build or install beyond the tools above. The CPU runs directly from source.

## Usage <a name = "usage"></a>

### Running the full CPU test

The most interesting test is the full CPU running a real program. This test loads a small program into the instruction memory and checks the register file after the program finishes.

```bash
iverilog -Wall -I rtl -o sim/tb_top.vvp \
    rtl/pc.v rtl/imem.v rtl/if_id.v rtl/decoder.v rtl/register.v \
    rtl/immgen.v rtl/id_ex.v rtl/alu.v rtl/forward.v rtl/hazard.v \
    rtl/branch.v rtl/ex_mem.v rtl/dmem.v rtl/mem_wb.v rtl/top.v \
    tb/tb_top.v

vvp sim/tb_top.vvp
```

You should see output like:

```
PASS result=5 expected_result=5
PASS result=7 expected_result=7
PASS result=9 expected_result=9
PASS result=b expected_result=b
PASS result=0 expected_result=0
PASS result=0 expected_result=0
All Tests Passed
```

### Running an individual module test

Each module has its own testbench. For example, to test the ALU:

```bash
iverilog -Wall -I rtl -o sim/tb_alu.vvp rtl/alu.v tb/tb_alu.v

vvp sim/tb_alu.vvp
```

### Viewing waveforms

Every testbench writes a `.vcd` file. To view one:

```bash
gtkwave tb_top.vcd
```

Inside GTKWave, expand the module tree on the left, then double-click signals to load them into the main window. The program counter, instruction, and pipeline register contents are good places to start.

### Writing your own test program

Test programs are plain text files in `programs/`. Each line contains one 32-bit instruction in hexadecimal.

For example, `programs/pipeline_test.hex`:

```
00500093   // addi x1, x0, 5   : x1 = 5
00700113   // addi x2, x0, 7   : x2 = 7
00900193   // addi x3, x0, 9   : x3 = 9
00B00213   // addi x4, x0, 11  : x4 = 11
00000073   // ecall           : halt
```

To use your own program, edit the hex file and update the `IMEM_INIT_FILE` parameter in your testbench. Then recompile and run.

If hand-encoding instructions is tedious (it is), the many online RV32I assemblers make it a non-issue simply use the one you like the look and feel of the most.

## Design Overview <a name = "design_overview"></a>

### What is a pipeline?

A pipeline is a way of splitting the work of a single instruction into several stages, so that multiple instructions can be in progress at once. It is like an assembly line: while one instruction is being fetched, the previous one is being decoded, and the one before that is being executed.

This CPU has five stages:

- **IF (Fetch):** Read the next instruction from memory.
- **ID (Decode):** Figure out what the instruction means. Read the source registers.
- **EX (Execute):** Do the math.
- **MEM (Memory):** Read or write data memory.
- **WB (Writeback):** Write the result into a register.

Between each pair of stages is a pipeline register. On each clock tick, every stage finishes its work and passes its result to the next stage.

### Hazards and how they are handled

Sometimes one instruction needs something a previous instruction has not yet produced. This CPU handles those cases in three ways:

1. **Forwarding:** If a value is sitting in a pipeline register and a later instruction needs it, the value is passed directly to the ALU instead of waiting for it to reach the register file.
2. **Load-use stall:** If a load is immediately followed by an instruction that needs the loaded value, the pipeline pauses for one cycle. The load finishes, then the next instruction continues.
3. **Branch flush:** If a branch is taken, the two instructions fetched after it are thrown away, and the pipeline refetches from the branch target.


## Limitations <a name = "limitations"></a>

- Simulation only. This project does not currently target an FPGA.
- No traps, CSRs, or privilege modes. `ecall` and `ebreak` currently signal the testbench to stop, rather than jumping to a trap handler.
- No interrupts.
- No caches.
- No extensions beyond RV32I. Multiply, divide, atomics, and floating point are not implemented.
- Misaligned memory access is not trapped.

## Future Work <a name = "future_work"></a>

Possible next steps for this project:

- **More test programs:** Fibonacci, sorting, and other small algorithms to exercise the CPU further.
- **Traps and CSRs:** Add exception handling so the CPU can respond to `ecall` and illegal instructions the way the RISC-V specification describes.
- **M extension:** Add multiply and divide.
- **FPGA synthesis:** Port the design to real hardware.
- **Caches:** Add instruction and data caches.
- **Simulator comparison:** Run the same programs on Spike (the official RISC-V simulator) and compare the register state.


