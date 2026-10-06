/*
// Module:      id_ex
// File:        rtl/id_ex.v
// Description: The Decode/Execute pipeline register. This is the largest of
//              the four lunchboxes between pipeline stages, because Decode
//              produces a lot of information and Execute needs all of it.
//
//
//              What this lunchbox carries:
//                - Data values: the two register values (rs1_value and
//                  rs2_value) read from the register file, the unpacked
//                  immediate, and the instruction's own PC.
//                - Register indices: rs1_addr, rs2_addr, and rd_addr. The
//                  first two are used by the forwarding unit to detect
//                  hazards. The third travels all the way to Writeback.
//                - Execute control: alu_control, alu_src, use_pc, branch,
//                  jump, jalr, and funct3. These tell the ALU and branch
//                  unit what to compute.
//                - Memory control: mem_read and mem_write.
//                - Writeback control: reg_write and wb_sel.
//                - System signals: sys_op and illegal, which travel to the
//                  end of the pipeline so the top level can react to them.
//
//              This register has two special behaviors beyond the usual
//              "copy inputs to outputs on the clock edge":
//
//                - flush: when high, every output clears to zero. This turns
//                  the instruction currently in Decode into a bubble, a
//                  do-nothing instruction that flows through Execute,
//                  Memory, and Writeback without affecting anything. Flush
//                  is used both when the hazard unit stalls (to keep the
//                  younger instruction in Decode) and when a branch is taken
//                  (to discard the wrongly-fetched instruction).
//
//                - reset: active-low. When asserted, every output clears to
//                  zero, giving the pipeline a clean starting state.
//
//              Priority order inside the always block: reset wins over flush,
//              flush wins over the normal copy. This ensures the register
//              always ends up in a known state when something goes wrong.
*/

`timescale 1ns/1ps
`include "definitions.vh"
module id_ex(
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input wire         stall,

    // Data values from Decode
    input  wire [31:0] rs1_value_in,
    input  wire [31:0] rs2_value_in,
    input  wire [31:0] immediate_in,
    input  wire [31:0] pc_in,

    // Register indices
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,

    // EX control
    input  wire [4:0]  alu_control_in,
    input  wire        alu_src_in,
    input  wire        use_pc_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire [2:0]  funct3_in,

    // MEM control
    input  wire        mem_read_in,
    input  wire        mem_write_in,

    // WB control
    input  wire        reg_write_in,
    input  wire [1:0]  wb_sel_in,

    // System
    input  wire [3:0]  sys_op_in,
    input  wire        illegal_in,
    input wire         jalr_in,

    // ---- outputs ----
    output reg  [31:0] rs1_value_out,
    output reg  [31:0] rs2_value_out,
    output reg  [31:0] immediate_out,
    output reg  [31:0] pc_out,

    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_addr_out,

    output reg  [4:0]  alu_control_out,
    output reg         alu_src_out,
    output reg         use_pc_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg  [2:0]  funct3_out,

    output reg         mem_read_out,
    output reg         mem_write_out,

    output reg         reg_write_out,
    output reg  [1:0]  wb_sel_out,

    output reg  [3:0]  sys_op_out,
    output reg         illegal_out,
    output reg         jalr_out
);

always @(posedge clk) begin
    if (rst == 0) begin
        rs1_value_out   <= 32'b0;
        rs2_value_out   <= 32'b0;
        immediate_out   <= 32'b0;
        pc_out          <= 32'b0;
        rs1_addr_out    <= 5'b0;
        rs2_addr_out    <= 5'b0;
        rd_addr_out     <= 5'b0;
        alu_control_out <= 5'b0;
        alu_src_out     <= 1'b0;
        use_pc_out      <= 1'b0;
        branch_out      <= 1'b0;
        jump_out        <= 1'b0;
        funct3_out      <= 3'b0;
        mem_read_out    <= 1'b0;
        mem_write_out   <= 1'b0;
        reg_write_out   <= 1'b0;
        wb_sel_out      <= 2'b0;
        sys_op_out      <= 4'b0;
        illegal_out     <= 1'b0;
        jalr_out        <= 1'b0;
    end else if(flush) begin 
        rs1_value_out   <= 32'b0;
        rs2_value_out   <= 32'b0;
        immediate_out   <= 32'b0;
        pc_out          <= 32'b0;
        rs1_addr_out    <= 5'b0;
        rs2_addr_out    <= 5'b0;
        rd_addr_out     <= 5'b0;
        alu_control_out <= 5'b0;
        alu_src_out     <= 1'b0;
        use_pc_out      <= 1'b0;
        branch_out      <= 1'b0;
        jump_out        <= 1'b0;
        funct3_out      <= 3'b0;
        mem_read_out    <= 1'b0;
        mem_write_out   <= 1'b0;
        reg_write_out   <= 1'b0;
        wb_sel_out      <= 2'b0;
        sys_op_out      <= 4'b0;
        illegal_out     <= 1'b0;
        jalr_out        <= 1'b0;
    end else if (stall) begin 
        
    end else begin
        rs1_value_out   <= rs1_value_in;
        rs2_value_out   <= rs2_value_in;
        immediate_out   <= immediate_in;
        pc_out          <= pc_in;
        rs1_addr_out    <= rs1_addr_in;
        rs2_addr_out    <= rs2_addr_in;
        rd_addr_out     <= rd_addr_in;
        alu_control_out <= alu_control_in;
        alu_src_out     <= alu_src_in;
        use_pc_out      <= use_pc_in;
        branch_out      <= branch_in;
        jump_out        <= jump_in;
        funct3_out      <= funct3_in;
        mem_read_out    <= mem_read_in;
        mem_write_out   <= mem_write_in;
        reg_write_out   <= reg_write_in;
        wb_sel_out      <= wb_sel_in;
        sys_op_out      <= sys_op_in;
        illegal_out     <= illegal_in;
        jalr_out        <= jalr_in;
    end
end

endmodule