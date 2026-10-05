# Collection of Risc-V work in Verilog

## Table of Contents
+ [About](#about)
+ [Features](#features)
+ [Project Structure](#project_structure)
+ [Getting Started](#getting_started)


## About <a name = "about"></a>

The goal of this project is a fully functional RISC-V SOC written in Verilog.

V1.0 currently implements the RV32I base integer instruction set (further info can be fount in the V1.0_RV32I_Core README).

## Project Structure <a name = "project_structure"></a>

```
V1.0_RV32I_Core/
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

These instructions will help you set up the foundation necessary for this project to work on you computer.

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
