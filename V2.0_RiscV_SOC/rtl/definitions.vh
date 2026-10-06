`ifndef DEFINITIONS_VH //include-guard macro ensures macros not defined more than once when included in multiple files
`define DEFINITIONS_VH

//ALU Operator Macros
`define ALU_ADD     5'd0 //addition
`define ALU_SUB     5'd1 //subtraction
`define ALU_AND     5'd2 //logical and
`define ALU_OR      5'd3 //logical or
`define ALU_XOR     5'd4 //logical exclusive or
`define ALU_SLT     5'd5 //set less than (signed)
`define ALU_SLTU    5'd6 //set less than (unsigned)
`define ALU_SLL     5'd7 //shift left logical
`define ALU_SRL     5'd8 //shift right logical
`define ALU_SRA     5'd9 //shift right arithmetic
`define ALU_PASS_A  5'd10 // pass a
`define ALU_PASS_B  5'd11 // pass b

//Immediate Type Macros
`define IMM_I    3'd0 //I-Type
`define IMM_S    3'd1 //S-Type
`define IMM_B    3'd2 //B-Type
`define IMM_U    3'd3 //U-Type
`define IMM_J    3'd4 //J-Type
`define IMM_NONE 3'd5 //No immediate

// RV32I Major Opcodes
`define OP_LUI      7'b0110111  // LUI: put big number in top of rd
`define OP_AUIPC    7'b0010111  // AUIPC: add big number to PC
`define OP_JAL      7'b1101111  // JAL: jump far, save return address
`define OP_JALR     7'b1100111  // JALR: jump to address in rs1
`define OP_BRANCH   7'b1100011  // branch group
`define OP_LOAD     7'b0000011  // load group
`define OP_STORE    7'b0100011  // store group
`define OP_I        7'b0010011  // math with immediate
`define OP_R        7'b0110011  // math register-register
`define OP_MISC_MEM 7'b0001111  // FENCE
`define OP_SYSTEM   7'b1110011  // ECALL, EBREAK

// Branch funct3
`define F3_BEQ  3'b000  // branch if rs1 == rs2
`define F3_BNE  3'b001  // branch if rs1 != rs2
`define F3_BLT  3'b100  // branch if rs1 < rs2 signed
`define F3_BGE  3'b101  // branch if rs1 >= rs2 signed
`define F3_BLTU 3'b110  // branch if rs1 < rs2 unsigned
`define F3_BGEU 3'b111  // branch if rs1 >= rs2 unsigned

// Load funct3
`define F3_LB   3'b000  // load byte, sign-extended
`define F3_LH   3'b001  // load halfword, sign-extended
`define F3_LW   3'b010  // load word
`define F3_LBU  3'b100  // load byte, zero-extended
`define F3_LHU  3'b101  // load halfword, zero-extended

// Store funct3
`define F3_SB   3'b000  // store byte
`define F3_SH   3'b001  // store halfword
`define F3_SW   3'b010  // store word

// I funct3
`define F3_ADDI  3'b000  // add immediate
`define F3_SLTI  3'b010  // signed less-than immediate
`define F3_SLTIU 3'b011  // unsigned less-than immediate
`define F3_XORI  3'b100  // XOR immediate
`define F3_ORI   3'b110  // OR immediate
`define F3_ANDI  3'b111  // AND immediate
`define F3_SLLI  3'b001  // shift left immediate
`define F3_SRI   3'b101  // shift right immediate; SRLI/SRAI by funct7 bit 5

// R funct3
`define F3_ADD_SUB 3'b000  // ADD or SUB, chosen by funct7
`define F3_SLL     3'b001  // shift left
`define F3_SLT     3'b010  // signed less-than
`define F3_SLTU    3'b011  // unsigned less-than
`define F3_XOR     3'b100  // XOR
`define F3_SR      3'b101  // SRL or SRA, chosen by funct7
`define F3_OR      3'b110  // OR
`define F3_AND     3'b111  // AND

// funct7 values (only two you need for RV32I)
`define FUNCT7_0   7'b0000000  // normal version: ADD, SRL, SLLI, SRLI
`define FUNCT7_32  7'b0100000  // alternate version: SUB, SRA, SRAI

// Writeback source selectors
`define WB_ALU 2'd0  // rd gets the ALU answer
`define WB_MEM 2'd1  // rd gets the loaded value from memory
`define WB_PC4 2'd2  // rd gets PC+4 (return address for jumps)

// MISC-MEM and SYSTEM
`define F3_FENCE     3'b000  // FENCE
`define F3_PRIV      3'b000  // SYSTEM: ECALL, EBREAK (and privileged later)
`define FUNCT12_ECALL  12'h000  // ECALL
`define FUNCT12_EBREAK 12'h001  // EBREAK
`define SYS_NONE   4'd0  // no system operation
`define SYS_ECALL  4'd1  // ECALL
`define SYS_EBREAK 4'd2  // EBREAK

//Forwarding unit selectors
`define FW_NONE 2'b00  // no forwarding; use the register file value
`define FW_MEM  2'b01  // forward from the EX/MEM pipeline register
`define FW_WB   2'b10  // forward from the MEM/WB pipeline register



`endif //DEFINITIONS_VH