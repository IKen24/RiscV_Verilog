/*
// Module:      pc
// File:        rtl/pc.v
// Description: The program counter is the CPU's bookmark. It holds
//              one 32-bit number: the address of the instruction the CPU
//              is currently working on.
//
//              On every rising clock edge, the PC loads whatever value is
//              sitting on its pc_next input. On the next edge, it loads
//              whatever is on pc_next then. So the PC always points to the
//              instruction that should be fetched next.
//
//              The PC has two control inputs. An active-low synchronous reset forces it
//              back to address zero. A stall input freezes it in place: while
//              stall is high, the PC holds its current value and ignores
//              pc_next, so the pipeline can pause for a cycle without losing
//              its place.
//
//              The PC does not add 4 to itself. It does not decide branch
//              targets. It does not know about jumps. All of that decision-
//              making happens outside, in the top-level module, which feeds
//              the correct next address into pc_next. The PC is deliberately
//              simple: hold a number, and update it when told.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module pc (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [31:0] pc_next,
    output reg [31:0] pc
);

always @(posedge clk) begin
    if(rst == 0)begin
        pc <= 32'b0;
    end else if(stall)begin 
        
    end else begin
        pc <= pc_next;
    end
    
end
    
endmodule