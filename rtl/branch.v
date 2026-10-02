`timescale 1ns/1ps
`include "definitions.vh"
module branch (
    input wire [2:0] funct3,
    input wire alu_zero,
    input wire [31:0] alu_result,
    input wire branch,
    input wire jump,

    output reg branch_taken
);

always @(*) begin
    branch_taken = 1'b0;
    if(jump)begin
        branch_taken = 1'b1;
    end else if (branch == 1) begin
        case (funct3)
            `F3_BEQ: branch_taken = alu_zero;
            `F3_BNE: branch_taken = ~alu_zero;
            `F3_BLT: branch_taken = alu_result[0];
            `F3_BGE: branch_taken = ~alu_result[0];
            `F3_BLTU: branch_taken = alu_result[0];
            `F3_BGEU: branch_taken = ~alu_result[0];
            default: branch_taken = 1'b0; 
        endcase
    end
end


endmodule