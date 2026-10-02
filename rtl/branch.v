/*
// Module:      branch
// File:        rtl/branch.v
// Description: The branch decision unit. When a branch or jump instruction
//              reaches the Execute stage, this module answers the question:
//              should the program counter jump to a new address, or should
//              it continue to the next instruction?
//
//              The answer is a single bit called branch_taken. When it is
//              high, the top-level module sends the PC to the computed
//              target address. When it is low, the PC simply advances by 4.
//
//              Jumps (JAL and JALR) are unconditional. The branch_taken
//              output is always high for them. Branches are conditional:
//              six different kinds, each checking a different comparison
//              between two registers.
//
//              For branches, the module looks at funct3 (which branch kind)
//              and at the ALU's outputs. The ALU has already compared the
//              two registers. For BEQ and BNE, the ALU's zero flag tells us
//              whether the two values were equal. For the four inequality
//              branches, the ALU has computed a "less than" result, and the
//              bottom bit of that result is either 1 (the comparison was
//              true) or 0 (it was false).
//
//              The module has no clock and no reset. It is pure combinational
//              logic: change the inputs, and branch_taken updates immediately.
//              This is essential, because the pipeline needs the branch
//              decision in the same cycle the branch is in Execute.
//
//              Note that this module does NOT compute the target address,
//              and it does NOT flush the pipeline. It only decides yes or
//              no. The top-level module uses its answer to redirect the PC
//              and throw away the wrongly-fetched instructions.
*/

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