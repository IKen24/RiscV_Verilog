/*
// Module:      ex_mem
// File:        rtl/ex_mem.v
// Description: The Execute/Memory pipeline register is one of the four
//              lunchboxes between pipeline stages. It carries data from the
//              Execute stage into the Memory stage on each clock edge.
//
//              Why a pipeline register is needed: every stage of the pipeline
//              is working on a different instruction at the same time. When
//              Execute finishes with one instruction, its results must be
//              held somewhere while the next instruction moves into Execute.
//              The pipeline register does exactly that: it captures the
//              current stage's outputs on one clock edge, and presents them
//              to the next stage on the following edge.
//
//              What this particular lunchbox carries:
//                - The ALU result (either the computed value or the memory
//                  address, depending on the instruction).
//                - The second source register value (rs2), which is the data
//                  that gets written to memory during a store.
//                - The return address for jumps (PC+4).
//                - The destination register number (rd), which must survive
//                  all the way to the Writeback stage.
//                - The width/sign selector (funct3), which the data memory
//                  needs to know how many bytes to read or write.
//                - The Memory stage control signals (mem_read, mem_write).
//                - The Writeback stage control signals (reg_write, wb_sel).
//                - The system-operation code and illegal-instruction flag,
//                  which travel all the way to the end of the pipeline.
//
//              What is NOT carried: signals that only matter in Execute, such
//              as the ALU control selector, the immediate, the raw PC, and
//              the two source register addresses. Their job is done by the
//              time the instruction leaves Execute.
//
//              On reset, every output clears to zero, giving the pipeline a
//              clean starting state. There is no flush input on this register
//              because the branch flush only affects the Fetch and Decode
//              stages, which are further back in the pipeline.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module ex_mem(
    input  wire        clk,
    input  wire        rst,
    input wire         stall,

    // Data from EX
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_value_in,
    input  wire [31:0] pc_plus_4_in,

    // Register destination
    input  wire [4:0]  rd_addr_in,

    // MEM control
    input  wire [2:0]  funct3_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,

    // WB control
    input  wire        reg_write_in,
    input  wire [1:0]  wb_sel_in,

    // System
    input  wire [3:0]  sys_op_in,
    input  wire        illegal_in,

    // ---- outputs ----
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_value_out,
    output reg  [31:0] pc_plus_4_out,

    output reg  [4:0]  rd_addr_out,

    output reg  [2:0]  funct3_out,
    output reg         mem_read_out,
    output reg         mem_write_out,

    output reg         reg_write_out,
    output reg  [1:0]  wb_sel_out,

    output reg  [3:0]  sys_op_out,
    output reg         illegal_out
);

always @(posedge clk) begin
    if (rst == 0) begin
        alu_result_out <= 32'b0;
        rs2_value_out  <= 32'b0;
        pc_plus_4_out  <= 32'b0;
        rd_addr_out    <= 5'b0;
        funct3_out     <= 3'b0;
        mem_read_out   <= 1'b0;
        mem_write_out  <= 1'b0;
        reg_write_out  <= 1'b0;
        wb_sel_out     <= 2'b0;
        sys_op_out     <= 4'b0;
        illegal_out    <= 1'b0;
    end else if(stall) begin 

    end else begin
        alu_result_out <= alu_result_in;
        rs2_value_out  <= rs2_value_in;
        pc_plus_4_out  <= pc_plus_4_in;
        rd_addr_out    <= rd_addr_in;
        funct3_out     <= funct3_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        reg_write_out  <= reg_write_in;
        wb_sel_out     <= wb_sel_in;
        sys_op_out     <= sys_op_in;
        illegal_out    <= illegal_in;
    end
end

endmodule