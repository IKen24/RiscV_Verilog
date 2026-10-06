/*
// Module:      mem_wb
// File:        rtl/mem_wb.v
// Description: The Memory/Writeback pipeline register. This is the last of
//              the four lunchboxes between pipeline stages. It carries the
//              final results from the Memory stage into the Writeback stage,
//              where they are written into the register file.
//
//
//              What this lunchbox carries:
//                - Three possible writeback values, only one of which will
//                  actually be written to the register file:
//                    - alu_result: for instructions that produce their
//                      answer in the ALU (arithmetic, logic, and so on).
//                    - read_data: for loads, which get their value from
//                      data memory.
//                    - pc_plus_4: for jumps (JAL and JALR), which write
//                      the return address.
//                  The wb_sel signal decides which of these three wins.
//                - The destination register number (rd_addr), which tells
//                  the register file which box to write into.
//                - The Writeback control signals (reg_write and wb_sel).
//                - The system-operation code and illegal-instruction flag,
//                  which are exposed to the top level so a testbench can
//                  detect ECALL and illegal instructions as they reach the
//                  end of the pipeline.
//
//              What is NOT carried: everything that has finished its job by
//              the end of the Memory stage. That includes the store data
//              (rs2_value), the width/sign selector (funct3), and the
//              memory control signals (mem_read and mem_write). None of
//              those matter anymore once the instruction has left Memory.
//
//              On reset, every output clears to zero, giving the pipeline a
//              clean starting state. There is no flush or stall input on
//              this register: by the time an instruction reaches the end of
//              the pipeline, it is always committed to memory or to the
//              register file. Nothing can throw it away now.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module mem_wb(
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,

    // Data from MEM
    input  wire [31:0] alu_result_in,
    input  wire [31:0] read_data_in,
    input  wire [31:0] pc_plus_4_in,

    // Register destination
    input  wire [4:0]  rd_addr_in,

    // WB control
    input  wire        reg_write_in,
    input  wire [1:0]  wb_sel_in,

    // System
    input  wire [3:0]  sys_op_in,
    input  wire        illegal_in,

    // ---- outputs ----
    output reg  [31:0] alu_result_out,
    output reg  [31:0] read_data_out,
    output reg  [31:0] pc_plus_4_out,

    output reg  [4:0]  rd_addr_out,

    output reg         reg_write_out,
    output reg  [1:0]  wb_sel_out,

    output reg  [3:0]  sys_op_out,
    output reg         illegal_out
);

always @(posedge clk) begin
    if (rst == 0) begin
        alu_result_out <= 32'b0;
        read_data_out  <= 32'b0;
        pc_plus_4_out  <= 32'b0;
        rd_addr_out    <= 5'b0;
        reg_write_out  <= 1'b0;
        wb_sel_out     <= 2'b0;
        sys_op_out     <= 4'b0;
        illegal_out    <= 1'b0;
    end else if (stall) begin 
        
    end else begin
        alu_result_out <= alu_result_in;
        read_data_out  <= read_data_in;
        pc_plus_4_out  <= pc_plus_4_in;
        rd_addr_out    <= rd_addr_in;
        reg_write_out  <= reg_write_in;
        wb_sel_out     <= wb_sel_in;
        sys_op_out     <= sys_op_in;
        illegal_out    <= illegal_in;
    end
end

endmodule