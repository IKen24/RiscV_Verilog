`timescale 1ns/1ps
`include "definitions.vh"
module imem #(
    parameter DEPTH      = 256,
    parameter INIT_FILE  = "programs/imem_test.hex"
)(
    input  wire [31:0] address,
    output wire [31:0] instruction
);

localparam INDEX_BITS = $clog2(DEPTH);

reg [31:0] mem [0:DEPTH-1];

initial $readmemh(INIT_FILE, mem);

assign instruction = mem[address[INDEX_BITS+1:2]];

endmodule