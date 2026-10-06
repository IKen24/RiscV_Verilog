`timescale 1ns/1ps
`include "definitions.vh"
module tb_mem_wb();

reg  clk;
reg  rst;

reg  [31:0] alu_result_in;
reg  [31:0] read_data_in;
reg  [31:0] pc_plus_4_in;
reg  [4:0]  rd_addr_in;
reg         reg_write_in;
reg  [1:0]  wb_sel_in;
reg  [3:0]  sys_op_in;
reg         illegal_in;

wire [31:0] alu_result_out;
wire [31:0] read_data_out;
wire [31:0] pc_plus_4_out;
wire [4:0]  rd_addr_out;
wire        reg_write_out;
wire [1:0]  wb_sel_out;
wire [3:0]  sys_op_out;
wire        illegal_out;

mem_wb dut(
    .clk(clk),
    .rst(rst),
    .alu_result_in(alu_result_in),
    .read_data_in(read_data_in),
    .pc_plus_4_in(pc_plus_4_in),
    .rd_addr_in(rd_addr_in),
    .reg_write_in(reg_write_in),
    .wb_sel_in(wb_sel_in),
    .sys_op_in(sys_op_in),
    .illegal_in(illegal_in),
    .alu_result_out(alu_result_out),
    .read_data_out(read_data_out),
    .pc_plus_4_out(pc_plus_4_out),
    .rd_addr_out(rd_addr_out),
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
    $dumpfile("tb_mem_wb.vcd");
    $dumpvars(0, tb_mem_wb);

    //Test 1 - reset clears all outputs
    rst = 0;
    alu_result_in = 32'hAAAAAAAA;
    read_data_in  = 32'hBBBBBBBB;
    pc_plus_4_in  = 32'hCCCCCCCC;
    rd_addr_in    = 5'd31;
    reg_write_in  = 1;
    wb_sel_in     = 2'b10;
    sys_op_in     = 4'd2;
    illegal_in    = 1;
    @(posedge clk);#1;
    check(alu_result_out, 32'h0);
    check(read_data_out, 32'h0);
    check(pc_plus_4_out, 32'h0);
    check(rd_addr_out, 5'd0);
    check(reg_write_out, 1'b0);
    check(wb_sel_out, 2'b0);
    check(sys_op_out, 4'd0);
    check(illegal_out, 1'b0);
    //Test 2 - release reset, all values flow through
    rst = 1;
    @(posedge clk);#1;
    check(alu_result_out, 32'hAAAAAAAA);
    check(read_data_out, 32'hBBBBBBBB);
    check(pc_plus_4_out, 32'hCCCCCCCC);
    check(rd_addr_out, 5'd31);
    check(reg_write_out, 1'b1);
    check(wb_sel_out, 2'b10);
    check(sys_op_out, 4'd2);
    check(illegal_out, 1'b1);
    //Test 3 - new values replace old (load instruction)
    alu_result_in = 32'h00000010;
    read_data_in  = 32'hDEADBEEF;
    pc_plus_4_in  = 32'h00000004;
    rd_addr_in    = 5'd5;
    reg_write_in  = 1;
    wb_sel_in     = `WB_MEM;
    sys_op_in     = `SYS_NONE;
    illegal_in    = 0;
    @(posedge clk);#1;
    check(alu_result_out, 32'h00000010);
    check(read_data_out, 32'hDEADBEEF);
    check(rd_addr_out, 5'd5);
    check(reg_write_out, 1'b1);
    check(wb_sel_out, `WB_MEM);
    check(sys_op_out, `SYS_NONE);
    //Test 4 - hold steady, outputs do not change
    @(posedge clk);#1;
    check(alu_result_out, 32'h00000010);
    check(read_data_out, 32'hDEADBEEF);
    check(rd_addr_out, 5'd5);
    check(wb_sel_out, `WB_MEM);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule