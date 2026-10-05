/*
// Module:      top
// File:        rtl/top.v
// Description: The top-level CPU. This is the map of the whole design. It
//              instantiates every module, wires the pipeline stages together,
//              and places the four pipeline registers between them. Nothing
//              computes anything interesting here all the real work happens
//              inside the submodules. The top level is the factory floor:
//              the workers and the lunchboxes, arranged in a line.
//
//              The five stages, in order:
//
//                IF   (Fetch): PC + imem. Gets the next instruction.
//                ID   (Decode): decoder + register file + immgen.
//                               Figures out what the instruction means,
//                               reads the source registers, unpacks the
//                               immediate.
//                EX   (Execute): ALU, forwarding muxes, branch unit.
//                                Does the math and decides branch/jump
//                                direction.
//                MEM  (Memory): dmem. Reads or writes data memory.
//                WB   (Writeback): the register file's write port. Puts
//                                    the final value where it belongs.
//
//              Between each pair of stages sits a pipeline register:
//              if_id, id_ex, ex_mem, and mem_wb. On every clock edge, each
//              of these captures its inputs and passes them to the next
//              stage, so up to five instructions can be in flight at once.
//
//              The top level also owns the small pieces of glue logic that
//              do not belong to any single stage:
//
//                - The PC+4 adder (assign pc_plus_4 = pc + 4).
//                - The PC-next mux, which chooses between PC+4 and the
//                  branch/jump target.
//                - The two ALU input muxes, which select between the
//                  forwarded register value, the raw register value, the
//                  immediate, or the PC.
//                - The branch target adder (id_ex_pc + id_ex_immediate).
//                - The redirect target mux, which chooses between the
//                  branch adder's output and the ALU result (for JALR).
//                - The writeback mux, which chooses between the ALU result,
//                  the loaded data, and PC+4.
//                - The flush and stall signals that keep the pipeline
//                  synchronized (drawn from the hazard unit and the branch
//                  unit).
//
//              Two internal modules produce signals that reach backward
//              through the pipeline:
//
//                - The forwarding unit drives two muxes in Execute, using
//                  register numbers from EX/MEM and MEM/WB.
//                - The branch unit drives the PC-next mux in Fetch, using
//                  the branch decision computed in Execute.
//
//              These backward paths are the only places in the design where
//              a signal flows against the direction of the pipeline. They
//              are just wires, but they are easy to overlook when tracing
//              through the design for the first time.
//
//              Parameters:
//                - IMEM_DEPTH      number of 32-bit words in instruction memory
//                - IMEM_INIT_FILE  path to the hex file holding the program
//                - DMEM_DEPTH      number of bytes in data memory
//
//              Ports:
//                - clk, rst        the two control inputs
//                - sys_op_out      exposed from MEM/WB so a testbench can
//                                  detect ECALL and stop the simulation
//                - illegal_out     exposed from MEM/WB so a testbench can
//                                  catch illegal instructions
//
*/

`timescale 1ns/1ps
`include "definitions.vh"

module top #(
    parameter IMEM_DEPTH     = 256,
    parameter IMEM_INIT_FILE = "programs/forward_test.hex",
    parameter DMEM_DEPTH     = 256
)(
    input  wire       clk,
    input  wire       rst,
    output wire [3:0] sys_op_out,
    output wire       illegal_out
);

// -------- Fetch stage wires --------
wire [31:0] pc;
wire [31:0] pc_plus_4;
wire [31:0] pc_next;
wire [31:0] instruction;

// -------- IF/ID lunchbox wires --------
wire [31:0] if_id_instruction;
wire [31:0] if_id_pc;

// -------- Decode stage wires --------
wire [4:0]  rs1, rs2, rd;
wire [4:0]  alu_control;
wire        alu_src;
wire        reg_write;
wire        mem_read;
wire        mem_write;
wire [1:0]  wb_sel;
wire        branch;
wire        jump;
wire [2:0]  imm_type;
wire        illegal;
wire        use_pc;
wire [3:0]  sys_op;
wire        jalr;

wire [31:0] rs1_value;
wire [31:0] rs2_value;
wire [31:0] immediate;

// -------- ID/EX lunchbox wires --------
wire [31:0] id_ex_rs1_value;
wire [31:0] id_ex_rs2_value;
wire [31:0] id_ex_immediate;
wire [31:0] id_ex_pc;
wire [4:0]  id_ex_rs1_addr;
wire [4:0]  id_ex_rs2_addr;
wire [4:0]  id_ex_rd_addr;
wire [4:0]  id_ex_alu_control;
wire        id_ex_alu_src;
wire        id_ex_use_pc;
wire        id_ex_branch;
wire        id_ex_jump;
wire [2:0]  id_ex_funct3;
wire        id_ex_mem_read;
wire        id_ex_mem_write;
wire        id_ex_reg_write;
wire [1:0]  id_ex_wb_sel;
wire [3:0]  id_ex_sys_op;
wire        id_ex_illegal;
wire        id_ex_jalr;

// -------- Execute stage wires --------
wire [31:0] alu_a;
wire [31:0] alu_b;
wire [31:0] alu_result;
wire        alu_zero;
wire [31:0] id_ex_pc_plus_4;

// -------- EX/MEM lunchbox wires --------
wire [31:0] ex_mem_alu_result;
wire [31:0] ex_mem_rs2_value;
wire [31:0] ex_mem_pc_plus_4;
wire [4:0]  ex_mem_rd_addr;
wire [2:0]  ex_mem_funct3;
wire        ex_mem_mem_read;
wire        ex_mem_mem_write;
wire        ex_mem_reg_write;
wire [1:0]  ex_mem_wb_sel;
wire [3:0]  ex_mem_sys_op;
wire        ex_mem_illegal;

// -------- Memory stage wires --------
wire [31:0] dmem_read_data;

// -------- MEM/WB lunchbox wires --------
wire [31:0] mem_wb_alu_result;
wire [31:0] mem_wb_read_data;
wire [31:0] mem_wb_pc_plus_4;
wire [4:0]  mem_wb_rd_addr;
wire        mem_wb_reg_write;
wire [1:0]  mem_wb_wb_sel;
wire [3:0]  mem_wb_sys_op;
wire        mem_wb_illegal;

// -------- Writeback wire --------
wire [31:0] wb_value;

// -------- Forwarding stage wires --------
wire [1:0]  forward_a;
wire [1:0]  forward_b;
wire [31:0] rs1_forwarded;
wire [31:0] rs2_forwarded;

// -------- Hazard stage wires --------
wire        stall;
wire        flush_id_ex;
wire [4:0]  if_id_rs1_addr;
wire [4:0]  if_id_rs2_addr;

// -------- Branch stage wires --------
wire        branch_taken;
wire        flush_if_id;
wire [31:0] ex_branch_target;
wire [31:0] ex_redirect_target;


// FETCH STAGE

pc pc_dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .pc_next(pc_next),
    .pc(pc)
);

imem #(
    .DEPTH(IMEM_DEPTH),
    .INIT_FILE(IMEM_INIT_FILE)
) imem_dut (
    .address(pc),
    .instruction(instruction)
);

assign pc_plus_4 = pc + 4;
assign pc_next = branch_taken ? ex_redirect_target : pc_plus_4;


// IF/ID PIPELINE REGISTER

if_id if_id_dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush_if_id),
    .instruction_in(instruction),
    .pc_in(pc),
    .instruction_out(if_id_instruction),
    .pc_out(if_id_pc)
);

assign if_id_rs1_addr = if_id_instruction[19:15];
assign if_id_rs2_addr = if_id_instruction[24:20];
assign flush_if_id = branch_taken;


// DECODE STAGE

decoder decoder_dut (
    .instruction(if_id_instruction),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .alu_control(alu_control),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .wb_sel(wb_sel),
    .branch(branch),
    .jump(jump),
    .imm_type(imm_type),
    .illegal(illegal),
    .use_pc(use_pc),
    .sys_op(sys_op),
    .jalr(jalr)
);

register regfile_dut (
    .clk(clk),
    .rst(rst),
    .read_addr1(rs1),
    .read_addr2(rs2),
    .write_addr(mem_wb_rd_addr),
    .write_data(wb_value),
    .write_enable(mem_wb_reg_write),
    .read_data1(rs1_value),
    .read_data2(rs2_value)
);

immgen immgen_dut (
    .instruction(if_id_instruction),
    .imm_type(imm_type),
    .immediate(immediate)
);


// ID/EX PIPELINE REGISTER

id_ex id_ex_dut (
    .clk(clk),
    .rst(rst),
    .flush(flush_id_ex),
    .rs1_value_in(rs1_value),
    .rs2_value_in(rs2_value),
    .immediate_in(immediate),
    .pc_in(if_id_pc),
    .rs1_addr_in(rs1),
    .rs2_addr_in(rs2),
    .rd_addr_in(rd),
    .alu_control_in(alu_control),
    .alu_src_in(alu_src),
    .use_pc_in(use_pc),
    .branch_in(branch),
    .jump_in(jump),
    .funct3_in(if_id_instruction[14:12]),
    .mem_read_in(mem_read),
    .mem_write_in(mem_write),
    .reg_write_in(reg_write),
    .wb_sel_in(wb_sel),
    .sys_op_in(sys_op),
    .illegal_in(illegal),
    .rs1_value_out(id_ex_rs1_value),
    .rs2_value_out(id_ex_rs2_value),
    .immediate_out(id_ex_immediate),
    .pc_out(id_ex_pc),
    .rs1_addr_out(id_ex_rs1_addr),
    .rs2_addr_out(id_ex_rs2_addr),
    .rd_addr_out(id_ex_rd_addr),
    .alu_control_out(id_ex_alu_control),
    .alu_src_out(id_ex_alu_src),
    .use_pc_out(id_ex_use_pc),
    .branch_out(id_ex_branch),
    .jump_out(id_ex_jump),
    .funct3_out(id_ex_funct3),
    .mem_read_out(id_ex_mem_read),
    .mem_write_out(id_ex_mem_write),
    .reg_write_out(id_ex_reg_write),
    .wb_sel_out(id_ex_wb_sel),
    .sys_op_out(id_ex_sys_op),
    .illegal_out(id_ex_illegal),
    .jalr_in(jalr),
    .jalr_out(id_ex_jalr)
);

assign flush_id_ex = stall | branch_taken;


// EXECUTE STAGE

assign alu_a = id_ex_use_pc ? id_ex_pc : rs1_forwarded;
assign alu_b = id_ex_alu_src ? id_ex_immediate : rs2_forwarded;
assign id_ex_pc_plus_4 = id_ex_pc + 4;

alu alu_dut (
    .a(alu_a),
    .b(alu_b),
    .alu_control(id_ex_alu_control),
    .result(alu_result),
    .zero(alu_zero)
);

assign ex_branch_target   = id_ex_pc + id_ex_immediate;
assign ex_redirect_target = id_ex_jalr ? alu_result : ex_branch_target;

branch branch_dut (
    .funct3(id_ex_funct3),
    .alu_zero(alu_zero),
    .alu_result(alu_result),
    .branch(id_ex_branch),
    .jump(id_ex_jump),
    .branch_taken(branch_taken)
);

// EX/MEM PIPELINE REGISTER

ex_mem ex_mem_dut (
    .clk(clk),
    .rst(rst),
    .alu_result_in(alu_result),
    .rs2_value_in(rs2_forwarded),
    .pc_plus_4_in(id_ex_pc_plus_4),
    .rd_addr_in(id_ex_rd_addr),
    .funct3_in(id_ex_funct3),
    .mem_read_in(id_ex_mem_read),
    .mem_write_in(id_ex_mem_write),
    .reg_write_in(id_ex_reg_write),
    .wb_sel_in(id_ex_wb_sel),
    .sys_op_in(id_ex_sys_op),
    .illegal_in(id_ex_illegal),
    .alu_result_out(ex_mem_alu_result),
    .rs2_value_out(ex_mem_rs2_value),
    .pc_plus_4_out(ex_mem_pc_plus_4),
    .rd_addr_out(ex_mem_rd_addr),
    .funct3_out(ex_mem_funct3),
    .mem_read_out(ex_mem_mem_read),
    .mem_write_out(ex_mem_mem_write),
    .reg_write_out(ex_mem_reg_write),
    .wb_sel_out(ex_mem_wb_sel),
    .sys_op_out(ex_mem_sys_op),
    .illegal_out(ex_mem_illegal)
);


// MEMORY STAGE

dmem #(
    .DEPTH(DMEM_DEPTH)
) dmem_dut (
    .clk(clk),
    .mem_read(ex_mem_mem_read),
    .mem_write(ex_mem_mem_write),
    .funct3(ex_mem_funct3),
    .address(ex_mem_alu_result),
    .write_data(ex_mem_rs2_value),
    .read_data(dmem_read_data)
);


// MEM/WB PIPELINE REGISTER

mem_wb mem_wb_dut (
    .clk(clk),
    .rst(rst),
    .alu_result_in(ex_mem_alu_result),
    .read_data_in(dmem_read_data),
    .pc_plus_4_in(ex_mem_pc_plus_4),
    .rd_addr_in(ex_mem_rd_addr),
    .reg_write_in(ex_mem_reg_write),
    .wb_sel_in(ex_mem_wb_sel),
    .sys_op_in(ex_mem_sys_op),
    .illegal_in(ex_mem_illegal),
    .alu_result_out(mem_wb_alu_result),
    .read_data_out(mem_wb_read_data),
    .pc_plus_4_out(mem_wb_pc_plus_4),
    .rd_addr_out(mem_wb_rd_addr),
    .reg_write_out(mem_wb_reg_write),
    .wb_sel_out(mem_wb_wb_sel),
    .sys_op_out(mem_wb_sys_op),
    .illegal_out(mem_wb_illegal)
);


// WRITEBACK STAGE

assign wb_value = (mem_wb_wb_sel == `WB_MEM) ? mem_wb_read_data :
                  (mem_wb_wb_sel == `WB_PC4) ? mem_wb_pc_plus_4 :
                                               mem_wb_alu_result;


//Forward Unit
forward forward_dut(
    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_rd_addr(ex_mem_rd_addr),
    .mem_wb_reg_write(mem_wb_reg_write),
    .mem_wb_rd_addr(mem_wb_rd_addr),
    .id_ex_rs1_addr(id_ex_rs1_addr),
    .id_ex_rs2_addr(id_ex_rs2_addr),
    .forward_a(forward_a),
    .forward_b(forward_b)
);

assign rs1_forwarded = (forward_a == `FW_MEM) ? ex_mem_alu_result :
                       (forward_a == `FW_WB)  ? wb_value          :
                                                id_ex_rs1_value;

assign rs2_forwarded = (forward_b == `FW_MEM) ? ex_mem_alu_result :
                       (forward_b == `FW_WB)  ? wb_value          :
                                                id_ex_rs2_value;


// HAZARD UNIT
hazard hazard_dut (
    .id_ex_mem_read (id_ex_mem_read),
    .id_ex_rd_addr  (id_ex_rd_addr),
    .if_id_rs1_addr (if_id_rs1_addr),
    .if_id_rs2_addr (if_id_rs2_addr),
    .stall          (stall)
);                                                

// EXPOSE SYSTEM SIGNALS TO TESTBENCH

assign sys_op_out  = mem_wb_sys_op;
assign illegal_out = mem_wb_illegal;

endmodule