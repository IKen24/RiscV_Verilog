`timescale 1ns/1ps
`include "definitions.vh"
module tb_ex_mem();

reg  clk;
reg  rst;

reg  [31:0] alu_result_in;
reg  [31:0] rs2_value_in;
reg  [31:0] pc_plus_4_in;
reg  [4:0]  rd_addr_in;
reg  [2:0]  funct3_in;
reg         mem_read_in;
reg         mem_write_in;
reg         reg_write_in;
reg  [1:0]  wb_sel_in;
reg  [3:0]  sys_op_in;
reg         illegal_in;

wire [31:0] alu_result_out;
wire [31:0] rs2_value_out;
wire [31:0] pc_plus_4_out;
wire [4:0]  rd_addr_out;
wire [2:0]  funct3_out;
wire        mem_read_out;
wire        mem_write_out;
wire        reg_write_out;
wire [1:0]  wb_sel_out;
wire [3:0]  sys_op_out;
wire        illegal_out;

ex_mem dut(
    .clk(clk),
    .rst(rst),
    .alu_result_in(alu_result_in),
    .rs2_value_in(rs2_value_in),
    .pc_plus_4_in(pc_plus_4_in),
    .rd_addr_in(rd_addr_in),
    .funct3_in(funct3_in),
    .mem_read_in(mem_read_in),
    .mem_write_in(mem_write_in),
    .reg_write_in(reg_write_in),
    .wb_sel_in(wb_sel_in),
    .sys_op_in(sys_op_in),
    .illegal_in(illegal_in),
    .alu_result_out(alu_result_out),
    .rs2_value_out(rs2_value_out),
    .pc_plus_4_out(pc_plus_4_out),
    .rd_addr_out(rd_addr_out),
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
    $dumpfile("tb_ex_mem.vcd");
    $dumpvars(0, tb_ex_mem);

    //Test 1 - reset clears all outputs
    rst = 0;
    alu_result_in = 32'hAAAAAAAA;
    rs2_value_in  = 32'hBBBBBBBB;
    pc_plus_4_in  = 32'hCCCCCCCC;
    rd_addr_in    = 5'd31;
    funct3_in     = 3'b111;
    mem_read_in   = 1;
    mem_write_in  = 1;
    reg_write_in  = 1;
    wb_sel_in     = 2'b10;
    sys_op_in     = 4'd2;
    illegal_in    = 1;
    @(posedge clk);#1;
    check(alu_result_out, 32'h0);
    check(rd_addr_out, 5'd0);
    check(funct3_out, 3'b0);
    check(reg_write_out, 1'b0);
    check(sys_op_out, 4'd0);
    //Test 2 - release reset, all values flow through
    rst = 1;
    @(posedge clk);#1;
    check(alu_result_out, 32'hAAAAAAAA);
    check(rs2_value_out, 32'hBBBBBBBB);
    check(pc_plus_4_out, 32'hCCCCCCCC);
    check(rd_addr_out, 5'd31);
    check(funct3_out, 3'b111);
    check(mem_read_out, 1'b1);
    check(mem_write_out, 1'b1);
    check(reg_write_out, 1'b1);
    check(wb_sel_out, 2'b10);
    check(sys_op_out, 4'd2);
    check(illegal_out, 1'b1);
    //Test 3 - new values replace old
    alu_result_in = 32'h00000010;
    rs2_value_in  = 32'h00000020;
    pc_plus_4_in  = 32'h00000004;
    rd_addr_in    = 5'd5;
    funct3_in     = `F3_LW;
    mem_read_in   = 1;
    mem_write_in  = 0;
    reg_write_in  = 1;
    wb_sel_in     = `WB_MEM;
    sys_op_in     = `SYS_NONE;
    illegal_in    = 0;
    @(posedge clk);#1;
    check(alu_result_out, 32'h00000010);
    check(rs2_value_out, 32'h00000020);
    check(rd_addr_out, 5'd5);
    check(funct3_out, `F3_LW);
    check(mem_read_out, 1'b1);
    check(mem_write_out, 1'b0);
    check(wb_sel_out, `WB_MEM);
    check(sys_op_out, `SYS_NONE);
    //Test 4 - hold steady, outputs do not change
    @(posedge clk);#1;
    check(alu_result_out, 32'h00000010);
    check(rd_addr_out, 5'd5);
    check(funct3_out, `F3_LW);
    check(mem_read_out, 1'b1);
    check(wb_sel_out, `WB_MEM);
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