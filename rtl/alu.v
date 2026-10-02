`timescale 1ns/1ps
`include "definitions.vh"
module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [4:0] alu_control,
    output reg [31:0] result,
    output wire zero
);

wire[4:0] shift_amount = b[4:0]; //shift ammount is lower 5 bits of b

always@(*)begin
    case (alu_control)
        `ALU_ADD: result = a + b;
        `ALU_SUB: result = a - b;
        `ALU_AND: result = a & b;
        `ALU_OR:  result = a | b;
        `ALU_XOR: result = a ^ b;
        `ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        `ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
        `ALU_SLL: result = a << shift_amount;
        `ALU_SRL: result = a >> shift_amount;
        `ALU_SRA: result = $signed(a) >>> shift_amount;
        `ALU_PASS_A: result = a;
        `ALU_PASS_B: result = b;
        default: result = 32'd0;
    endcase
end

assign zero = (result == 32'd0);

endmodule