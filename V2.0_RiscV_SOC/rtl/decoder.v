/*
// Module:      decoder
// File:        rtl/decoder.v
// Description: Every 32-bit RISC-V instruction is
//              a puzzle piece: hidden inside it are the answers to "what
//              does this instruction do?", "which registers does it touch?",
//              "does it use an immediate?", and so on. The decoder's job is
//              to look at the instruction word and set every control signal
//              that the rest of the pipeline needs.
//
//              The decoder has one input: the raw 32-bit instruction. It
//              produces many outputs. These fall into four groups:
//
//                1. Register indices - rs1 (first source register), 
//                   rs2 (second source register), and rd (destination 
//                   register). Always sliced from the same bit positions, 
//                   no matter the instruction format.
//
//                2. ALU hints: alu_control and alu_src. These tell the ALU
//                   which operation to perform and whether its second input
//                   should come from a register or from the immediate.
//
//                3. Pipeline control switches: reg_write, mem_read,
//                   mem_write, wb_sel, branch, and jump. These tell the
//                   later stages of the pipeline what to do with the result.
//
//                4. Immediate and error signals: imm_type tells the
//                   immediate generator which format to unpack, and illegal
//                   goes high when the instruction does not match any valid
//                   RV32I pattern.
//
//              The decoder is combinational: no clock, no reset, no memory.
//              Change the instruction, and every output updates immediately.
//
//              The module works by first slicing out the opcode (the main
//              instruction group), plus funct3 and funct7 (smaller selectors
//              used inside a group). It then runs one large case statement on
//              the opcode. Three groups, R, I, and Branch, need a second-level
//              case on funct3 (and sometimes funct7) to pick the exact ALU
//              operation. Every other group has the same control signals for
//              all its instructions, so no inner case is needed.
//
//              All outputs are set to safe defaults at the top of the always
//              block. Each case branch then overrides only the signals that
//              are different from the defaults. Anything that falls through
//              to the outer default branch is marked as illegal.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module decoder(
    input wire [31:0] instruction,

    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,

    output reg [4:0] alu_control,
    output reg alu_src, //is b an immediate or from a register 0 for register 1 for immediate

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] wb_sel,
    output reg branch,
    output reg jump,

    output reg [2:0] imm_type,
    output reg illegal,

    output reg        use_pc,   // 1 = AUIPC: ALU's A input comes from PC, not rs1
    output reg [3:0]  sys_op,    // which system instruction (ECALL, EBREAK, none)
    output reg        jalr
);
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [11:0] funct12;

assign funct12 = instruction[31:20];
assign opcode = instruction[6:0];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

always @(*) begin
    rs1 = instruction[19:15]; 
    rs2 = instruction[24:20]; 
    rd = instruction[11:7]; 
    alu_control = 5'b0;
    alu_src = 1'b0; 
    reg_write = 1'b0; 
    mem_read = 1'b0; 
    mem_write = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    illegal = 1'b0;
    wb_sel = `WB_ALU;
    imm_type = `IMM_NONE;
    use_pc = 1'b0;
    sys_op = `SYS_NONE;
    jalr = 1'b0;

    case (opcode)
        `OP_R: begin
            reg_write = 1'b1;
            alu_src = 1'b0;
            wb_sel = `WB_ALU;
            imm_type = `IMM_NONE;
            case({funct7, funct3})
                {`FUNCT7_0, `F3_ADD_SUB}: alu_control = `ALU_ADD;
                {`FUNCT7_32, `F3_ADD_SUB}: alu_control = `ALU_SUB;
                {`FUNCT7_0, `F3_SLL}: alu_control = `ALU_SLL;
                {`FUNCT7_0, `F3_SLT}: alu_control = `ALU_SLT;
                {`FUNCT7_0, `F3_SLTU}: alu_control = `ALU_SLTU;
                {`FUNCT7_0, `F3_XOR}: alu_control = `ALU_XOR;
                {`FUNCT7_0, `F3_SR}: alu_control = `ALU_SRL;
                {`FUNCT7_32, `F3_SR}: alu_control = `ALU_SRA;
                {`FUNCT7_0, `F3_OR}: alu_control = `ALU_OR;
                {`FUNCT7_0, `F3_AND}: alu_control = `ALU_AND;
                default: illegal = 1'b1;
            endcase
        end
        
        `OP_I:begin
            reg_write = 1'b1;
            alu_src = 1'b1;
            wb_sel = `WB_ALU;
            imm_type = `IMM_I;
            case(funct3)
                `F3_ADDI: alu_control = `ALU_ADD;
                `F3_SLTI: alu_control = `ALU_SLT;
                `F3_SLTIU: alu_control = `ALU_SLTU;
                `F3_XORI: alu_control = `ALU_XOR;
                `F3_ORI: alu_control = `ALU_OR;
                `F3_ANDI: alu_control = `ALU_AND;
                `F3_SLLI: alu_control = `ALU_SLL;
                `F3_SRI: begin
                    if(funct7 == `FUNCT7_0)begin
                        alu_control = `ALU_SRL;
                    end else if (funct7 == `FUNCT7_32)begin
                        alu_control = `ALU_SRA;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        `OP_LOAD: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = `ALU_ADD;
            mem_read    = 1'b1;
            mem_write   = 1'b0;
            wb_sel      = `WB_MEM;
            branch      = 1'b0;
            jump        = 1'b0;
            imm_type    = `IMM_I;
        end

        `OP_STORE: begin
            reg_write   = 1'b0;
            alu_src     = 1'b1;
            alu_control = `ALU_ADD;
            mem_read    = 1'b0;
            mem_write   = 1'b1;
            wb_sel      = `WB_ALU;
            branch      = 1'b0;
            jump        = 1'b0;
            imm_type    = `IMM_S;
        end

        `OP_BRANCH: begin
            reg_write   = 1'b0;
            alu_src     = 1'b0;
            mem_read    = 1'b0;
            mem_write   = 1'b0;
            wb_sel      = `WB_ALU;
            branch      = 1'b1;
            jump        = 1'b0;
            imm_type    = `IMM_B;
            case (funct3)
                `F3_BEQ:  alu_control = `ALU_SUB;
                `F3_BNE:  alu_control = `ALU_SUB;
                `F3_BLT:  alu_control = `ALU_SLT;
                `F3_BGE:  alu_control = `ALU_SLT;
                `F3_BLTU: alu_control = `ALU_SLTU;
                `F3_BGEU: alu_control = `ALU_SLTU;
                default:  illegal = 1'b1;
            endcase
        end

        `OP_JAL: begin
            reg_write = 1'b1;
            wb_sel    = `WB_PC4;
            jump      = 1'b1;
            imm_type  = `IMM_J;
        end

        `OP_JALR: begin
            jalr        = 1'b1;
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = `ALU_ADD;
            wb_sel      = `WB_PC4;
            jump        = 1'b1;
            imm_type    = `IMM_I;
        end

        `OP_LUI: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = `ALU_PASS_B;
            wb_sel      = `WB_ALU;
            imm_type    = `IMM_U;
        end

        `OP_AUIPC: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = `ALU_ADD;
            wb_sel      = `WB_ALU;
            imm_type    = `IMM_U;
            use_pc      = 1'b1;
        end

        `OP_MISC_MEM: begin
            // treat as no-op for now.
        end

        `OP_SYSTEM: begin
            case (funct12)
                `FUNCT12_ECALL:  sys_op = `SYS_ECALL;
                `FUNCT12_EBREAK: sys_op = `SYS_EBREAK;
                default: illegal = 1'b1;
            endcase
            imm_type = `IMM_NONE;
        end

        default: illegal = 1'b1;
    endcase

    
end
endmodule