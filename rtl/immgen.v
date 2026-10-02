/*
// Module:      immgen
// File:        rtl/immgen.v
// Description: Many RISC-V instructions carry a
//              small number baked into the instruction word. That
//              number is called an "immediate". This module digs it out and
//              hands it back as a full 32-bit value.
//
//              The module has two inputs: the raw 32-bit instruction and a
//              3-bit selector saying which of the five RISC-V immediate
//              formats to use (I, S, B, U, or J). It has one output: the
//              completed 32-bit immediate, ready for the ALU or PC adder.
//
//              The five formats each hold the immediate in a different part
//              of the instruction word. Some put all the bits in one place.
//              Others scatter the bits across the instruction, so the module
//              has to gather them back together in the right order.
//
//              Four of the five formats produce a signed number. That means
//              the top bit of the immediate is copied into all the upper
//              positions of the 32-bit result, so a small negative number
//              becomes a proper negative 32-bit value. The fifth format
//              (U-type) places its immediate in the top 20 bits and fills
//              the bottom 12 bits with zeros; no sign extension is needed.
//
//              The module has no clock and no reset. It is pure combinational
//              logic: change the instruction or the selector, and the output
//              updates immediately.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module immgen(
    input wire [31:0] instruction,
    input wire [2:0] imm_type,
    output reg [31:0] immediate
);

always @(*) begin
    case (imm_type)
        `IMM_I: immediate = {{20{instruction[31]}}, instruction[31:20]};
        `IMM_S: immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        `IMM_B: immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        `IMM_U: immediate = {instruction[31:12], 12'b0};
        `IMM_J: immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        default: immediate = 32'd0; 
    endcase
end
endmodule