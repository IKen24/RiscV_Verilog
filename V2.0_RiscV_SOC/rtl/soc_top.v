/*
// Module:      soc_top
// File:        rtl/soc_top.v
// Description: The system-on-chip top level. This is the motherboard: it
//              instantiates the CPU core, the instruction memory slave, and
//              the data memory slave, and wires them together.
//
//              There is no logic in this file beyond instantiations and a
//              few assign statements to tie unused signals to safe values.
//              Every real device lives in its own module.
//
//              Right now the CPU talks to the instruction memory through
//              the Wishbone I-bus slave. The data path is still using the
//              core's direct dmem_* ports; the D-bus slave is instantiated
//              but its bus side is idle until the core's D-bus FSM is added.
//
//              Parameters:
//                IMEM_DEPTH      number of 32-bit words in instruction memory
//                IMEM_INIT_FILE  path to the hex file holding the program
//                DMEM_DEPTH      number of bytes in data memory
//                IBUS_LATENCY    wait cycles inserted by the imem slave
//                DBUS_LATENCY    wait cycles inserted by the dmem slave
*/

`timescale 1ns/1ps
`include "definitions.vh"

module soc_top #(
    parameter IMEM_DEPTH     = 256,
    parameter IMEM_INIT_FILE = "programs/hazard_test.hex",
    parameter DMEM_DEPTH     = 256,
    parameter IBUS_LATENCY   = 3,
    parameter DBUS_LATENCY   = 3
)(
    input  wire       clk,
    input  wire       rst,
    output wire [3:0] sys_op_out,
    output wire       illegal_out
);

// ---- Wires between core and instruction memory slave ----
wire [31:0] wb_ibus_adr;
wire [31:0] wb_ibus_dat;
wire        wb_ibus_cyc;
wire        wb_ibus_stb;
wire        wb_ibus_ack;

// ---- Wires between core and data memory slave ----
wire [31:0] wb_dbus_adr;
wire [31:0] wb_dbus_dat_o;
wire [31:0] wb_dbus_dat_i;
wire        wb_dbus_we;
wire [3:0]  wb_dbus_sel;
wire        wb_dbus_cyc;
wire        wb_dbus_stb;
wire        wb_dbus_ack;




// CPU CORE

riscv_core core_dut (
    .clk(clk),
    .rst(rst),

    // Wishbone I-bus
    .wb_ibus_adr_o(wb_ibus_adr),
    .wb_ibus_dat_i(wb_ibus_dat),
    .wb_ibus_cyc_o(wb_ibus_cyc),
    .wb_ibus_stb_o(wb_ibus_stb),
    .wb_ibus_ack_i(wb_ibus_ack),

    // Wishbone D-bus (bus side idle until core D-bus FSM is added)
    .wb_dbus_adr_o(wb_dbus_adr),
    .wb_dbus_dat_o(wb_dbus_dat_o),
    .wb_dbus_dat_i(wb_dbus_dat_i),
    .wb_dbus_we_o(wb_dbus_we),
    .wb_dbus_sel_o(wb_dbus_sel),
    .wb_dbus_cyc_o(wb_dbus_cyc),
    .wb_dbus_stb_o(wb_dbus_stb),
    .wb_dbus_ack_i(wb_dbus_ack),

    .sys_op_out(sys_op_out),
    .illegal_out(illegal_out)
);


// INSTRUCTION MEMORY SLAVE (Wishbone)

wb_imem_slave #(
    .DEPTH(IMEM_DEPTH),
    .INIT_FILE(IMEM_INIT_FILE),
    .LATENCY(IBUS_LATENCY)
) imem_slave_dut (
    .clk(clk),
    .rst(rst),
    .wb_adr_i(wb_ibus_adr),
    .wb_dat_o(wb_ibus_dat),
    .wb_cyc_i(wb_ibus_cyc),
    .wb_stb_i(wb_ibus_stb),
    .wb_ack_o(wb_ibus_ack)
);


// DATA MEMORY SLAVE (Wishbone)
// Instantiated now so the wiring is ready, but its bus side is idle
// until the core's D-bus FSM is added in the next step.

wb_dmem_slave #(
    .DEPTH(DMEM_DEPTH),
    .LATENCY(DBUS_LATENCY)
) dmem_slave_dut (
    .clk(clk),
    .rst(rst),
    .wb_adr_i(wb_dbus_adr),
    .wb_dat_i(wb_dbus_dat_o),
    .wb_dat_o(wb_dbus_dat_i),
    .wb_we_i(wb_dbus_we),
    .wb_sel_i(wb_dbus_sel),
    .wb_cyc_i(wb_dbus_cyc),
    .wb_stb_i(wb_dbus_stb),
    .wb_ack_o(wb_dbus_ack)
);


endmodule