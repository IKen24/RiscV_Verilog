/*
// Module:      dmem
// File:        rtl/dmem.v
// Description: Data memory is the CPU's street of numbered mailboxes.
//              Each mailbox holds one byte, and each byte has its own address.
//              Programs use this memory to store values that do not fit in
//              registers: arrays, strings, saved results, and so on.
//
//              Unlike the register file, data memory is read and written
//              during program execution. Writes happen on the rising clock
//              edge, and only when the write-enable signal is high. Reads
//              are immediate: change the address, and the byte value appears
//              on the output right away, without waiting for a clock edge.
//
//              The CPU can read or write 1 byte, 2 bytes, or 4 bytes at a
//              time. A 3-bit control signal (funct3) tells the memory which
//              width to use. For loads, funct3 also says whether to sign-
//              extend the result (fill the upper bits with the top bit) or
//              zero-extend it (fill the upper bits with zeros).
//
//              Multi-byte values are stored little-endian: the smallest part
//              of the number lives at the lowest address. For example, a
//              4-byte write puts byte 0 at address A, byte 1 at A+1, byte 2
//              at A+2, and byte 3 at A+3.
//
//              Data memory has no reset. Real memory does not clear itself
//              when power comes on, and neither does this one. It holds
//              whatever was last written. Any address that was never written
//              reads back as unknown (X in simulation), which 
//              makes bugs from uninitialized reads easy to spot.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module dmem #(parameter DEPTH = 256)(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [2:0] funct3,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

reg [7:0] mem [0:DEPTH - 1];

always @(posedge clk)begin
    if(mem_write)begin
        case (funct3)
            `F3_SB: mem[address] <= write_data[7:0];
            `F3_SH: begin mem[address] <= write_data[7:0]; mem[address + 1] <= write_data[15:8];  end
            `F3_SW: begin mem[address] <= write_data[7:0]; mem[address + 1] <= write_data[15:8]; mem[address + 2] <= write_data[23:16]; mem[address + 3] <= write_data[31:24]; end 
            default: ; 
        endcase
    end
end

always @(*)begin
    if(mem_read)begin
        case(funct3)
        `F3_LB: read_data = {{24{mem[address][7]}},mem[address]};
        `F3_LH: read_data = {{16{mem[address + 1][7]}}, mem[address + 1], mem[address]};
        `F3_LW: read_data = {mem[address + 3], mem[address + 2], mem[address + 1], mem[address]};
        `F3_LBU:read_data = {24'b0,mem[address]};
        `F3_LHU:read_data = {16'b0, mem[address + 1], mem[address]};
        default: read_data = 32'b0;
        endcase
    end else begin read_data = 32'b0; end

end
endmodule