`timescale 1ns/1ps
`include "definitions.vh"
module tb_imem();

reg  clk;
reg  rst;
wire [31:0] pc_next;
wire [31:0] pc;
wire [31:0] instruction;

assign pc_next = pc + 4;

pc pc_dut (
    .clk(clk),
    .rst(rst),
    .pc_next(pc_next),
    .pc(pc)
);

imem imem_dut(
    .address(pc),
    .instruction(instruction)
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
    $dumpfile("tb_imem.vcd");
    $dumpvars(0, tb_imem);

    rst = 0;
    #17;
    //Test 1 - during reset: add x1, x2, x3
    check(pc, 32'h0); check(instruction, 32'h003100B3);
    //Test 2 - release reset, first clock: addi x4, x5, 0
    rst = 1;
    @(posedge clk);#1;check(pc, 32'h4); check(instruction, 32'h00028213);
    //Test 3 - lw x6, 0(x7)
    @(posedge clk);#1;check(pc, 32'h8); check(instruction, 32'h0003A303);
    //Test 4 - sw x8, 0(x9)
    @(posedge clk);#1;check(pc, 32'hC); check(instruction, 32'h0084A023);
    //Test 5 - ecall
    @(posedge clk);#1;check(pc, 32'h10); check(instruction, 32'h00000073);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule