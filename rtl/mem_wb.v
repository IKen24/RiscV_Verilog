`timescale 1ns/1ps
`include "definitions.vh"
module mem_wb(
    input  wire        clk,
    input  wire        rst,

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