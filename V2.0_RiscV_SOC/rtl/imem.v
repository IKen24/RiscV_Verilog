/*
// Module:      imem
// File:        rtl/imem.v
// Description: Instruction memory is the CPU's cookbook. It holds the
//              program: a list of 32-bit instruction words, one after another.
//              Given an address, it hands back the instruction stored there.
//
//              The module is read-only during simulation. The program is
//              loaded once at the start from a text file of hexadecimal
//              values using $readmemh. After that, nothing ever writes to it.
//
//              The module has no clock. Reading is immediate: change the
//              address, and the instruction at that address appears on the
//              output right away. This is possible because instructions are
//              fetched every cycle and must be ready in the same cycle they
//              are requested.
//
//              The array inside holds 32-bit words, but the address input is
//              a byte address. Since every instruction is four bytes long,
//              the bottom two bits of the address are always zero and are
//              dropped before indexing the array. In other words, address 0
//              selects word 0, address 4 selects word 1, address 8 selects
//              word 2, and so on.
//
//              Both the size of the memory and the path to the program file
//              are parameters, so a testbench can swap in a different program
//              without editing this file.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module imem #(
    parameter DEPTH      = 256,
    parameter INIT_FILE  = "programs/imem_test.hex"
)(
    input  wire [31:0] address,
    output wire [31:0] instruction
);

localparam INDEX_BITS = $clog2(DEPTH);

reg [31:0] mem [0:DEPTH-1];

initial $readmemh(INIT_FILE, mem);

assign instruction = mem[address[INDEX_BITS+1:2]];

endmodule