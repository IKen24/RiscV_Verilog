/*
// Module:      wb_dmem_slave
// File:        rtl/wb_dmem_slave.v
// Description: A Wishbone slave that acts as the CPU's data memory. It has
//              its own internal byte array and speaks the standard Wishbone
//              handshake on the bus side.
//
//              Reads always return a full 32-bit word, assembled from four
//              consecutive bytes in little-endian order. The master is
//              responsible for extracting the byte or halfword it actually
//              wanted and for sign- or zero-extending it. This keeps the
//              slave ignorant of RISC-V details.
//
//              Writes use the byte-select signals. Only the bytes whose
//              select bit is high are written; the rest of the word is
//              left untouched. This is how a byte store, halfword store,
//              and word store all work through the same interface.
//
//              The slave inserts a fixed number of wait cycles before
//              acknowledging, so the CPU's memory stage has to wait for
//              real latency.
//
//              Parameters:
//                DEPTH      number of bytes in the internal array
//                LATENCY    number of wait cycles before asserting ack
*/

`timescale 1ns/1ps
`include "definitions.vh"

module wb_dmem_slave #(
    parameter DEPTH   = 256,
    parameter LATENCY = 3
)(
    input  wire        clk,
    input  wire        rst,

    // Wishbone slave interface
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    output reg         wb_ack_o
);

localparam IDLE = 2'd0;
localparam WAIT = 2'd1;
localparam DONE = 2'd2;

reg [7:0]  mem [0:DEPTH-1];
reg [1:0]  state;
reg [31:0] captured_addr;
reg [2:0]  delay_count;

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

                    if (wb_we_i) begin
                        if (wb_sel_i[0]) mem[wb_adr_i]     <= wb_dat_i[7:0];
                        if (wb_sel_i[1]) mem[wb_adr_i + 1] <= wb_dat_i[15:8];
                        if (wb_sel_i[2]) mem[wb_adr_i + 2] <= wb_dat_i[23:16];
                        if (wb_sel_i[3]) mem[wb_adr_i + 3] <= wb_dat_i[31:24];
                    end

                    delay_count <= LATENCY;
                    state       <= WAIT;
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
                wb_dat_o <= {mem[captured_addr + 3],
                             mem[captured_addr + 2],
                             mem[captured_addr + 1],
                             mem[captured_addr]};
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