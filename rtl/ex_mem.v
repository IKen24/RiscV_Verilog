`timescale 1ns/1ps
`include "definitions.vh"
module ex_mem(
    input  wire        clk,
    input  wire        rst,

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