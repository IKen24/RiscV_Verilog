`timescale 1ns/1ps
`include "definitions.vh"
module tb_id_ex();

reg  clk;
reg  rst;

reg  [31:0] rs1_value_in;
reg  [31:0] rs2_value_in;
reg  [31:0] immediate_in;
reg  [31:0] pc_in;

reg  [4:0]  rs1_addr_in;
reg  [4:0]  rs2_addr_in;
reg  [4:0]  rd_addr_in;

reg  [4:0]  alu_control_in;
reg         alu_src_in;
reg         use_pc_in;
reg         branch_in;
reg         jump_in;
reg  [2:0]  funct3_in;

reg         mem_read_in;
reg         mem_write_in;

reg         reg_write_in;
reg  [1:0]  wb_sel_in;

reg  [3:0]  sys_op_in;
reg         illegal_in;

wire [31:0] rs1_value_out;
wire [31:0] rs2_value_out;
wire [31:0] immediate_out;
wire [31:0] pc_out;

wire [4:0]  rs1_addr_out;
wire [4:0]  rs2_addr_out;
wire [4:0]  rd_addr_out;

wire [4:0]  alu_control_out;
wire        alu_src_out;
wire        use_pc_out;
wire        branch_out;
wire        jump_out;
wire [2:0]  funct3_out;

wire        mem_read_out;
wire        mem_write_out;

wire        reg_write_out;
wire [1:0]  wb_sel_out;

wire [3:0]  sys_op_out;
wire        illegal_out;

id_ex dut(
    .clk(clk),
    .rst(rst),
    .rs1_value_in(rs1_value_in),
    .rs2_value_in(rs2_value_in),
    .immediate_in(immediate_in),
    .pc_in(pc_in),
    .rs1_addr_in(rs1_addr_in),
    .rs2_addr_in(rs2_addr_in),
    .rd_addr_in(rd_addr_in),
    .alu_control_in(alu_control_in),
    .alu_src_in(alu_src_in),
    .use_pc_in(use_pc_in),
    .branch_in(branch_in),
    .jump_in(jump_in),
    .funct3_in(funct3_in),
    .mem_read_in(mem_read_in),
    .mem_write_in(mem_write_in),
    .reg_write_in(reg_write_in),
    .wb_sel_in(wb_sel_in),
    .sys_op_in(sys_op_in),
    .illegal_in(illegal_in),
    .rs1_value_out(rs1_value_out),
    .rs2_value_out(rs2_value_out),
    .immediate_out(immediate_out),
    .pc_out(pc_out),
    .rs1_addr_out(rs1_addr_out),
    .rs2_addr_out(rs2_addr_out),
    .rd_addr_out(rd_addr_out),
    .alu_control_out(alu_control_out),
    .alu_src_out(alu_src_out),
    .use_pc_out(use_pc_out),
    .branch_out(branch_out),
    .jump_out(jump_out),
    .funct3_out(funct3_out),
    .mem_read_out(mem_read_out),
    .mem_write_out(mem_write_out),
    .reg_write_out(reg_write_out),
    .wb_sel_out(wb_sel_out),
    .sys_op_out(sys_op_out),
    .illegal_out(illegal_out)
);

initial clk = 0;
always #5 clk = ~clk;

integer errors = 0;
task check(input [31:0] a, input [31:0] b);
    if (a !== b) begin
        $display("FAIL result=%0h expected_result=%0h", a, b);
        errors = errors + 1;
    end else $display("PASS result=%0h expected_result=%0h", a, b);
endtask

initial begin
    $dumpfile("tb_id_ex.vcd");
    $dumpvars(0, tb_id_ex);

    //Test 1 - reset clears all outputs to 0
    rst = 0;
    rs1_value_in = 32'hAAAAAAAA;
    rs2_value_in = 32'hBBBBBBBB;
    immediate_in = 32'hCCCCCCCC;
    pc_in = 32'hDDDDDDDD;
    rs1_addr_in = 5'd31;
    rs2_addr_in = 5'd30;
    rd_addr_in = 5'd29;
    alu_control_in = 5'd11;
    alu_src_in = 1;
    use_pc_in = 1;
    branch_in = 1;
    jump_in = 1;
    funct3_in = 3'b111;
    mem_read_in = 1;
    mem_write_in = 1;
    reg_write_in = 1;
    wb_sel_in = 2'b10;
    sys_op_in = 4'd2;
    illegal_in = 1;
    @(posedge clk);#1;
    check(rs1_value_out, 32'h0);
    check(rd_addr_out, 5'd0);
    check(alu_control_out, 5'd0);
    check(reg_write_out, 1'b0);
    check(sys_op_out, 4'd0);
    //Test 2 - release reset, all values flow through
    rst = 1;
    @(posedge clk);#1;
    check(rs1_value_out, 32'hAAAAAAAA);
    check(rs2_value_out, 32'hBBBBBBBB);
    check(immediate_out, 32'hCCCCCCCC);
    check(pc_out, 32'hDDDDDDDD);
    check(rs1_addr_out, 5'd31);
    check(rs2_addr_out, 5'd30);
    check(rd_addr_out, 5'd29);
    check(alu_control_out, 5'd11);
    check(alu_src_out, 1'b1);
    check(use_pc_out, 1'b1);
    check(branch_out, 1'b1);
    check(jump_out, 1'b1);
    check(funct3_out, 3'b111);
    check(mem_read_out, 1'b1);
    check(mem_write_out, 1'b1);
    check(reg_write_out, 1'b1);
    check(wb_sel_out, 2'b10);
    check(sys_op_out, 4'd2);
    check(illegal_out, 1'b1);
    //Test 3 - new values replace old ones
    rs1_value_in = 32'h11111111;
    rs2_value_in = 32'h22222222;
    immediate_in = 32'h0000000A;
    pc_in = 32'h00000004;
    rs1_addr_in = 5'd1;
    rs2_addr_in = 5'd2;
    rd_addr_in = 5'd3;
    alu_control_in = `ALU_ADD;
    alu_src_in = 0;
    use_pc_in = 0;
    branch_in = 0;
    jump_in = 0;
    funct3_in = 3'b000;
    mem_read_in = 0;
    mem_write_in = 0;
    reg_write_in = 0;
    wb_sel_in = `WB_ALU;
    sys_op_in = `SYS_NONE;
    illegal_in = 0;
    @(posedge clk);#1;
    check(rs1_value_out, 32'h11111111);
    check(pc_out, 32'h00000004);
    check(rd_addr_out, 5'd3);
    check(alu_control_out, `ALU_ADD);
    check(reg_write_out, 1'b0);
    check(sys_op_out, `SYS_NONE);
    //Test 4 - hold inputs steady, outputs do not change
    @(posedge clk);#1;
    check(rs1_value_out, 32'h11111111);
    check(pc_out, 32'h00000004);
    check(rd_addr_out, 5'd3);
    check(alu_control_out, `ALU_ADD);
    check(reg_write_out, 1'b0);
    check(sys_op_out, `SYS_NONE);
    #10;

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule