/*
// Module:      register
// File:        rtl/register.v
// Description: The register file is the CPU's short-term memory: a
//              shelf of 32 boxes, each holding one 32-bit number. Programs
//              keep their working values here.
//
//              Two boxes can be read at the same time. Reading is immediate:
//              change the address, and the value appears on the output right
//              away, without waiting for a clock edge.
//
//              One box can be written per clock cycle, but only if the write
//              enable is high. Box 0 (called x0) is special: it always reads
//              as zero, and any attempt to write to it is ignored.
//
//              The file also has an active-low synchronous reset. While reset is held,
//              every box is cleared to zero.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module register(
    input wire clk,
    input wire rst,
    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    input wire [4:0] write_addr,
    input wire [31:0] write_data,
    input wire write_enable,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

integer i;

reg [31:0] regs [0:31];

assign read_data1 = (read_addr1 == 0) ? 32'b0: regs[read_addr1];
assign read_data2 = (read_addr2 == 0) ? 32'b0: regs[read_addr2];

always @(posedge clk) begin
    if (rst == 0) begin
        for (i=0;i<32;i=i+1) regs[i] <= 32'b0; //reset sets all regs to zero    
    end else if(rst == 1 && (write_enable && write_addr != 5'b0))begin
        regs[write_addr] <= write_data;
    end
end

endmodule