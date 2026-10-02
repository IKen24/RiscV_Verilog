`timescale 1ns/1ps
`include "definitions.vh"
module immgen(
    input wire [31:0] instruction,
    input wire [2:0] imm_type,
    output reg [31:0] immediate
);

always @(*) begin
    case (imm_type)
        `IMM_I: immediate = {{20{instruction[31]}}, instruction[31:20]};
        `IMM_S: immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        `IMM_B: immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        `IMM_U: immediate = {instruction[31:12], 12'b0};
        `IMM_J: immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        default: immediate = 32'd0; 
    endcase
end
endmodule