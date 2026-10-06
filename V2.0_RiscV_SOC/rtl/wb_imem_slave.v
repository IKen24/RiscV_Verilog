/*
// Module:      wb_imem_slave
// File:        rtl/wb_imem_slave.v
// Description: A Wishbone slave that wraps the instruction memory. On the
//              bus side it speaks the standard Wishbone handshake (cycle,
//              strobe, acknowledge). On the memory side it drives the
//              simple address/instruction interface of the existing imem
//              module.
//
//              The slave inserts a fixed number of wait cycles before
//              acknowledging, so the CPU's fetch state machine has to
//              actually wait for memory to respond. This models a real
//              memory with latency, rather than a zero-cycle magic device.
//
//              Read-only. There is no write path, no write-enable input,
//              and no byte-select input, because instruction memory never
//              changes after it is loaded.
//
//              Parameters:
//                DEPTH      number of 32-bit words in the internal imem
//                INIT_FILE  path to the hex file that holds the program
//                LATENCY    number of wait cycles before asserting ack
*/

`timescale 1ns/1ps
`include "definitions.vh"

module wb_imem_slave #(
    parameter DEPTH     = 256,
    parameter INIT_FILE = "programs/pipeline_test.hex",
    parameter LATENCY   = 3
)(
    input  wire        clk,
    input  wire        rst,

    // Wishbone slave interface
    input  wire [31:0] wb_adr_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    output reg         wb_ack_o
);

localparam IDLE = 2'd0;
localparam WAIT = 2'd1;
localparam DONE = 2'd2;

reg [1:0]  state;
reg [31:0] captured_addr;
reg [2:0]  delay_count;

wire [31:0] imem_data;

imem #(
    .DEPTH(DEPTH),
    .INIT_FILE(INIT_FILE)
) imem_dut (
    .address(captured_addr),
    .instruction(imem_data)
);

always @(posedge clk) begin
    if (rst == 0) begin
        state         <= IDLE;
        wb_ack_o      <= 1'b0;
        wb_dat_o      <= 32'b0;
        captured_addr <= 32'b0;
        delay_count   <= 3'd0;
    end else begin
        case (state)
            IDLE: begin
                wb_ack_o <= 1'b0;
                if (wb_cyc_i && wb_stb_i) begin
                    captured_addr <= wb_adr_i;
                    delay_count   <= LATENCY;
                    state         <= WAIT;
                end
            end

            WAIT: begin
                if (delay_count > 1) begin
                    delay_count <= delay_count - 1;
                end else begin
                    state <= DONE;
                end
            end

            DONE: begin
                wb_dat_o <= imem_data;
                wb_ack_o <= 1'b1;
                state    <= IDLE;
            end

            default: begin
                state    <= IDLE;
                wb_ack_o <= 1'b0;
            end
        endcase
    end
end

endmodule