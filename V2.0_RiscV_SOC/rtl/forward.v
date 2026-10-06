/*
// Module:      forward
// File:        rtl/forward.v
// Description: The forwarding unit. Instructions in a pipeline overlap in
//              time, so an instruction often needs a value that a previous
//              instruction has computed but not yet written back to the
//              register file. Without help, it would read a stale value and
//              produce a wrong answer.
//
//              This module watches for those cases and tells the Execute
//              stage where to grab the fresh value instead. It does not move
//              any data itself. It only produces two small selectors,
//              forward_a and forward_b, and the top-level module uses them
//              to choose what the ALU actually reads.
//
//              Each selector has three possible values:
//                FW_NONE: no forwarding needed; use the register file value
//                FW_MEM: forward the value from the EX/MEM pipeline register
//                FW_WB: forward the value from the MEM/WB pipeline register
//
//              The rules for A (the same rules apply to B, using rs2 instead
//              of rs1):
//
//                1. If the instruction currently in EX/MEM is writing to a
//                   register, and that register is not x0, and it matches
//                   this instruction's rs1, forward from EX/MEM.
//
//                2. Otherwise, if the instruction currently in MEM/WB is
//                   writing to a register, and that register is not x0, and
//                   it matches this instruction's rs1, forward from MEM/WB.
//
//                3. Otherwise, no forwarding; the register file has the value.
//
//              Why EX/MEM is checked first: it is the fresher source. If both
//              pipeline stages happen to be writing the same register, the
//              EX/MEM value is the newer one. Forwarding the older value
//              would give a wrong result.
//
//              Why x0 is excluded: register x0 is hardwired to zero, and any
//              write to it is silently ignored by the register file. Forwarding
//              from a nonexistent write would push garbage into the ALU.
//
//              The module has no clock and no reset. It is pure combinational
//              logic: the selectors must be ready in the same cycle the ALU
//              is deciding what to compute.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module forward(
    input wire ex_mem_reg_write,
    input wire [4:0] ex_mem_rd_addr,

    input wire mem_wb_reg_write,
    input wire [4:0] mem_wb_rd_addr,

    input wire [4:0] id_ex_rs1_addr,
    input wire [4:0] id_ex_rs2_addr,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

always @(*) begin
    forward_a = `FW_NONE;
    forward_b = `FW_NONE;

    if((ex_mem_reg_write == 1) && (ex_mem_rd_addr !== 0) && (ex_mem_rd_addr == id_ex_rs1_addr))begin
        forward_a = `FW_MEM;
    end else if((mem_wb_reg_write == 1) && (mem_wb_rd_addr !== 0) && (mem_wb_rd_addr == id_ex_rs1_addr))begin
        forward_a = `FW_WB;
    end else begin forward_a = `FW_NONE; end

    if((ex_mem_reg_write == 1) && (ex_mem_rd_addr !== 0) && (ex_mem_rd_addr == id_ex_rs2_addr))begin
        forward_b = `FW_MEM;
    end else if((mem_wb_reg_write == 1) && (mem_wb_rd_addr !== 0) && (mem_wb_rd_addr == id_ex_rs2_addr))begin
        forward_b = `FW_WB;
    end else begin forward_b = `FW_NONE; end

end
endmodule