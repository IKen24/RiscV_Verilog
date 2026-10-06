/*
// Module:      riscv_core
// File:        rtl/riscv_core.v
// Description:  
//
*/

`timescale 1ns/1ps
`include "definitions.vh"

module riscv_core(
    input  wire       clk,
    input  wire       rst,

    // ---- Instruction Memory Interface ----
    output wire [31:0] wb_ibus_adr_o,
    input wire [31:0] wb_ibus_dat_i,
    output reg wb_ibus_cyc_o,
    output reg wb_ibus_stb_o,
    input wire wb_ibus_ack_i,

    // ---- Data Memory Interface ----
    output wire [31:0] wb_dbus_adr_o,
    output wire [31:0] wb_dbus_dat_o,
    input  wire [31:0] wb_dbus_dat_i,
    output wire        wb_dbus_we_o,
    output wire [3:0]  wb_dbus_sel_o,
    output reg         wb_dbus_cyc_o,
    output reg         wb_dbus_stb_o,
    input  wire        wb_dbus_ack_i,

    // ---- System signals exposed for testbench ----
    output wire [3:0]  sys_op_out,
    output wire        illegal_out
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
wire        hazard_stall;

// -------- Branch stage wires --------
wire        branch_taken;
wire        flush_if_id;
wire [31:0] ex_branch_target;
wire [31:0] ex_redirect_target;

// -------- D-Bus (data memory) FSM wires --------
wire        dbus_stall;
wire [31:0] dmem_read_data_raw;
wire [31:0] dmem_read_data_extracted;
reg [3:0]  dbus_sel;


// FETCH STAGE

wire stall_pc = branch_taken ? 1'b0 : stall;

pc pc_dut (
    .clk(clk),
    .rst(rst),
    .stall(stall_pc),
    .pc_next(pc_next),
    .pc(pc)
);

assign pc_plus_4 = pc + 4;
assign pc_next = branch_taken ? ex_redirect_target : pc_plus_4;
assign wb_ibus_adr_o = pc;

localparam [1:0] IDLE = 2'b00;
localparam [1:0] WAIT = 2'b01;
localparam [1:0] DONE = 2'b10;
reg [1:0] ibus_state;
reg [31:0] fetched_instruction;

wire ibus_stall;
assign ibus_stall = (ibus_state == IDLE) | (ibus_state == WAIT);

always @(posedge clk) begin
    if (rst == 0) begin
        ibus_state <= IDLE;
        wb_ibus_cyc_o <= 0;
        wb_ibus_stb_o <= 0;
        fetched_instruction <= 0;
    end else if (branch_taken) begin
        // Panic button: abort transaction and reset state
        ibus_state <= IDLE;
        wb_ibus_cyc_o <= 0;
        wb_ibus_stb_o <= 0;
        fetched_instruction <= 0; 
    end else begin
        case (ibus_state)
            IDLE: begin
                // We have a new PC, request the instruction
                wb_ibus_cyc_o <= 1;
                wb_ibus_stb_o <= 1;
                ibus_state <= WAIT; // Transition to WAIT
            end
            
            WAIT: begin
                if (wb_ibus_ack_i == 1) begin
                    // Transaction complete! Capture data and drop request.
                    fetched_instruction <= wb_ibus_dat_i;
                    wb_ibus_cyc_o <= 0;
                    wb_ibus_stb_o <= 0;
                    ibus_state <= DONE;
                end else begin
                    // Memory is still thinking. Hold the request.
                    wb_ibus_cyc_o <= 1;
                    wb_ibus_stb_o <= 1;
                    ibus_state <= WAIT; // Explicitly stay in WAIT
                end
            end

            DONE: begin
                if (!stall) begin
                    ibus_state <= IDLE;
                end
                // else: hold in DONE until the pipeline is ready to consume
            end
            
            default: begin
                // Safety net
                ibus_state <= IDLE;
                wb_ibus_cyc_o <= 0;
                wb_ibus_stb_o <= 0;
            end
        endcase
    end
end

assign instruction = fetched_instruction;

assign wb_dbus_adr_o = ex_mem_alu_result;
assign wb_dbus_dat_o = ex_mem_rs2_value;
assign wb_dbus_we_o  = ex_mem_mem_write;
assign wb_dbus_sel_o = dbus_sel;

localparam DBUS_IDLE = 2'b00;
localparam DBUS_WAIT = 2'b01;
localparam DBUS_DONE = 2'b10;
reg [1:0] dbus_state;
reg [31:0] dmem_read_data_raw_reg;
reg dbus_serviced;
reg  [31:0] serviced_addr;
reg         serviced_we;
reg         serviced_valid;
wire [31:0] cur_addr  = ex_mem_alu_result;
wire        cur_we    = ex_mem_mem_write;
wire        cur_memop = ex_mem_mem_read | ex_mem_mem_write;

wire is_new_memop = cur_memop &&
                    (!serviced_valid || serviced_addr != cur_addr || serviced_we != cur_we);

always @(posedge clk) begin
    if (rst == 0) begin
        dbus_state             <= DBUS_IDLE;
        wb_dbus_cyc_o          <= 1'b0;
        wb_dbus_stb_o          <= 1'b0;
        dmem_read_data_raw_reg <= 32'b0;
        serviced_addr          <= 32'b0;
        serviced_we            <= 1'b0;
        serviced_valid         <= 1'b0;
    end else begin
        case (dbus_state)
            DBUS_IDLE: begin
                wb_dbus_cyc_o <= 1'b0;
                wb_dbus_stb_o <= 1'b0;
                if (is_new_memop) begin
                    wb_dbus_cyc_o <= 1'b1;
                    wb_dbus_stb_o <= 1'b1;
                    serviced_addr <= cur_addr;
                    serviced_we   <= cur_we;
                    serviced_valid <= 1'b1;
                    dbus_state    <= DBUS_WAIT;
                end
            end

            DBUS_WAIT: begin
                wb_dbus_cyc_o <= 1'b1;
                wb_dbus_stb_o <= 1'b1;
                if (wb_dbus_ack_i) begin
                    wb_dbus_cyc_o <= 1'b0;
                    wb_dbus_stb_o <= 1'b0;
                    if (ex_mem_mem_read) begin
                        case (ex_mem_funct3)
                            `F3_LB: case (ex_mem_alu_result[1:0])
                                2'b00: dmem_read_data_raw_reg <= {{24{wb_dbus_dat_i[7]}},  wb_dbus_dat_i[7:0]};
                                2'b01: dmem_read_data_raw_reg <= {{24{wb_dbus_dat_i[15]}}, wb_dbus_dat_i[15:8]};
                                2'b10: dmem_read_data_raw_reg <= {{24{wb_dbus_dat_i[23]}}, wb_dbus_dat_i[23:16]};
                                2'b11: dmem_read_data_raw_reg <= {{24{wb_dbus_dat_i[31]}}, wb_dbus_dat_i[31:24]};
                            endcase
                            `F3_LBU: case (ex_mem_alu_result[1:0])
                                2'b00: dmem_read_data_raw_reg <= {24'b0, wb_dbus_dat_i[7:0]};
                                2'b01: dmem_read_data_raw_reg <= {24'b0, wb_dbus_dat_i[15:8]};
                                2'b10: dmem_read_data_raw_reg <= {24'b0, wb_dbus_dat_i[23:16]};
                                2'b11: dmem_read_data_raw_reg <= {24'b0, wb_dbus_dat_i[31:24]};
                            endcase
                            `F3_LH: case (ex_mem_alu_result[1])
                                1'b0: dmem_read_data_raw_reg <= {{16{wb_dbus_dat_i[15]}}, wb_dbus_dat_i[15:0]};
                                1'b1: dmem_read_data_raw_reg <= {{16{wb_dbus_dat_i[31]}}, wb_dbus_dat_i[31:16]};
                            endcase
                            `F3_LHU: case (ex_mem_alu_result[1])
                                1'b0: dmem_read_data_raw_reg <= {16'b0, wb_dbus_dat_i[15:0]};
                                1'b1: dmem_read_data_raw_reg <= {16'b0, wb_dbus_dat_i[31:16]};
                            endcase
                            default: dmem_read_data_raw_reg <= wb_dbus_dat_i;
                        endcase
                    end
                    dbus_state <= DBUS_DONE;
                end
            end

            DBUS_DONE: begin
                wb_dbus_cyc_o <= 1'b0;
                wb_dbus_stb_o <= 1'b0;
                dbus_state    <= DBUS_IDLE;
            end

            default: begin
                dbus_state    <= DBUS_IDLE;
                wb_dbus_cyc_o <= 1'b0;
                wb_dbus_stb_o <= 1'b0;
            end
        endcase
    end
end

assign dmem_read_data_raw = dmem_read_data_raw_reg;

always @(*) begin
    case (ex_mem_funct3)
        `F3_SB: dbus_sel = 4'b0001 << ex_mem_alu_result[1:0];
        `F3_SH: dbus_sel = 4'b0011 << {ex_mem_alu_result[1], 1'b0};
        `F3_SW: dbus_sel = 4'b1111;
        default: dbus_sel = 4'b1111;
    endcase
end





assign dmem_read_data_extracted = dmem_read_data_raw_reg;

assign dbus_stall = (dbus_state == DBUS_WAIT) |
                    (dbus_state == DBUS_IDLE && is_new_memop);

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
    .stall(dbus_stall),
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

assign flush_id_ex = (hazard_stall & ~dbus_stall) | branch_taken;


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
    .stall(dbus_stall),
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

//MEMORY STAGE



// MEM/WB PIPELINE REGISTER

mem_wb mem_wb_dut (
    .clk(clk),
    .rst(rst),
    .stall(dbus_stall),
    .alu_result_in(ex_mem_alu_result),
    .read_data_in(dmem_read_data_extracted),
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
    .stall          (hazard_stall)
);    
                                       

assign stall = hazard_stall | ibus_stall | dbus_stall;
// EXPOSE SYSTEM SIGNALS TO TESTBENCH

assign sys_op_out  = mem_wb_sys_op;
assign illegal_out = mem_wb_illegal;

endmodule