/*
// Module:      soc_top
// File:        rtl/soc_top.v
// Description: 
*/

`timescale 1ns/1ps
`include "definitions.vh"

module soc_top #(
    parameter IMEM_DEPTH     = 256,
    parameter IMEM_INIT_FILE = "programs/forward_test.hex",
    parameter DMEM_DEPTH     = 256
)(
    input  wire       clk,
    input  wire       rst,
    output wire [3:0] sys_op_out,
    output wire       illegal_out
);

// ---- Wires between core and instruction memory ----
wire [31:0] imem_address;
wire [31:0] imem_instruction;

// ---- Wires between core and data memory ----
wire        dmem_mem_read;
wire        dmem_mem_write;
wire [2:0]  dmem_funct3;
wire [31:0] dmem_address;
wire [31:0] dmem_write_data;
wire [31:0] dmem_read_data;

wire [31:0] wb_ibus_adr;
wire [31:0] wb_ibus_dat;
wire        wb_ibus_cyc;
wire        wb_ibus_stb;
wire        wb_ibus_ack;


// CPU CORE

riscv_core core_dut (
    .clk(clk),
    .rst(rst),

    .wb_ibus_adr_o(wb_ibus_adr),
    .wb_ibus_dat_i(wb_ibus_dat),
    .wb_ibus_cyc_o(wb_ibus_cyc),
    .wb_ibus_stb_o(wb_ibus_stb),
    .wb_ibus_ack_i(wb_ibus_ack),

    .dmem_mem_read(dmem_mem_read),
    .dmem_mem_write(dmem_mem_write),
    .dmem_funct3(dmem_funct3),
    .dmem_address(dmem_address),
    .dmem_write_data(dmem_write_data),
    .dmem_read_data(dmem_read_data),

    .sys_op_out(sys_op_out),
    .illegal_out(illegal_out)
);

// INSTRUCTION MEMORY

imem #(
    .DEPTH(IMEM_DEPTH),
    .INIT_FILE(IMEM_INIT_FILE)
) imem_dut (
    .address(wb_ibus_adr),
    .instruction(wb_ibus_dat)
);

reg [2:0] delay_count;
reg       delayed_ack;

always @(posedge clk) begin
    if (rst == 0) begin
        delay_count <= 0;
        delayed_ack <= 0;
    end else if (wb_ibus_stb && !delayed_ack && delay_count == 0) begin
        delay_count <= 3;      // wait 3 cycles
    end else if (delay_count > 0) begin
        delay_count <= delay_count - 1;
        if (delay_count == 1) delayed_ack <= 1;
    end else if (delayed_ack) begin
        delayed_ack <= 0;
    end
end

assign wb_ibus_ack = delayed_ack;


// DATA MEMORY

dmem #(
    .DEPTH(DMEM_DEPTH)
) dmem_dut (
    .clk(clk),
    .mem_read(dmem_mem_read),
    .mem_write(dmem_mem_write),
    .funct3(dmem_funct3),
    .address(dmem_address),
    .write_data(dmem_write_data),
    .read_data(dmem_read_data)
);

endmodule