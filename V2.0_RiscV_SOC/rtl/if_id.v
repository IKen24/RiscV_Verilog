/*
// Module:      if_id
// File:        rtl/if_id.v
// Description: The Fetch/Decode pipeline register. This is the smallest of
//              the four lunchboxes between pipeline stages. It carries only
//              two things from the Fetch stage into the Decode stage: the
//              raw instruction word, and the address that instruction came
//              from (its PC).
//
//
//              Why only two signals: at the Fetch stage, nothing else exists
//              yet. The instruction has not been decoded, the immediate has
//              not been unpacked, and no registers have been read. All of
//              that happens later, downstream of this register.
//
//              Why the instruction's own PC is carried and not PC+4: later
//              instructions need the address of the instruction currently
//              being executed. AUIPC computes PC + immediate, branches
//              compute PC + offset, and jumps compute PC + 4 to form a
//              return address. All of those need the instruction's own
//              address, not the address of the next one.
//
//              This register has two special behaviors beyond the usual
//              "copy inputs to outputs on the clock edge":
//
//                - flush: when high, both outputs clear to zero. This turns
//                  the instruction currently in Decode into a bubble, a
//                  do-nothing instruction that flows through the rest of
//                  the pipeline harmlessly. Flush fires when a branch is
//                  taken, because the instructions fetched after the branch
//                  were based on a wrong guess about the PC.
//
//                - stall: when high, the register holds its current value
//                  instead of loading new inputs. Stall fires when the
//                  hazard unit detects a load-use hazard. The instruction
//                  in Decode is correct, but must wait one cycle before it
//                  can proceed. Meanwhile, the PC is also frozen, so the
//                  same instruction is not fetched twice.
//
//              Priority order inside the always block: reset wins over
//              flush, flush wins over stall, stall wins over the normal
//              copy. This ensures the correct behavior when more than one
//              condition is true at the same time.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module if_id(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,
    input wire [31:0] instruction_in,
    input wire [31:0] pc_in,
    output reg [31:0] instruction_out,
    output reg [31:0] pc_out
);

always @(posedge clk) begin
    if(rst == 0)begin
        instruction_out <= 32'b0;
        pc_out <= 32'b0;
    end else if (flush) begin 
        instruction_out <= 32'b0;
        pc_out <= 32'b0;
    end else if (stall) begin 
        
    end else begin 
        instruction_out <= instruction_in;
        pc_out <= pc_in;
    end
end
endmodule