`timescale 1ns/1ps
`include "definitions.vh"
module tb_if_id();

reg  clk;
reg  rst;
reg  [31:0] instruction_in;
reg  [31:0] pc_in;
wire [31:0] instruction_out;
wire [31:0] pc_out;

if_id dut(
    .clk(clk),
    .rst(rst),
    .instruction_in(instruction_in),
    .pc_in(pc_in),
    .instruction_out(instruction_out),
    .pc_out(pc_out)
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
    $dumpfile("tb_if_id.vcd");
    $dumpvars(0, tb_if_id);

    //Test 1 - reset clears both outputs to 0
    rst = 0;
    instruction_in = 32'h003100B3;
    pc_in = 32'h00000000;
    @(posedge clk);#1;
    check(instruction_out, 32'h0);
    check(pc_out, 32'h0);
    //Test 2 - release reset, first instruction flows through
    rst = 1;
    instruction_in = 32'h003100B3;
    pc_in = 32'h00000000;
    @(posedge clk);#1;
    check(instruction_out, 32'h003100B3);
    check(pc_out, 32'h00000000);
    //Test 3 - new instruction, PC advances by 4
    instruction_in = 32'h00028213;
    pc_in = 32'h00000004;
    @(posedge clk);#1;
    check(instruction_out, 32'h00028213);
    check(pc_out, 32'h00000004);
    //Test 4 - hold inputs steady, outputs should stay the same
    instruction_in = 32'h00028213;
    pc_in = 32'h00000004;
    @(posedge clk);#1;
    check(instruction_out, 32'h00028213);
    check(pc_out, 32'h00000004);
    //Test 5 - third instruction, PC advances by 4 again
    instruction_in = 32'h0003A303;
    pc_in = 32'h00000008;
    @(posedge clk);#1;
    check(instruction_out, 32'h0003A303);
    check(pc_out, 32'h00000008);
    //Test 6 - reset mid-stream clears outputs immediately
    rst = 0;
    @(posedge clk);#1;
    check(instruction_out, 32'h0);
    check(pc_out, 32'h0);
    #10;

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule