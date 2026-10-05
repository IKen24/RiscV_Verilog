`timescale 1ns/1ps
`include "definitions.vh"
module tb_pc();
reg clk;
reg rst;
reg [31:0] pc_next;
wire [31:0] pc;

pc dut (
    .clk(clk),
    .rst(rst),
    .pc_next(pc_next),
    .pc(pc)
);

initial clk = 0;
always #5 clk = ~clk;

integer errors = 0;
task check(input [31:0] a, input [31:0] b);
    if (a!== b)begin
        $display("FAIL got=%0h expected=%0h", a, b);
        errors = errors + 1;
    end else $display("PASS got=%0h expected=%0h", a, b);
endtask

initial begin
    $dumpfile("tb_pc.vcd");
    $dumpvars(0, tb_pc);

    rst = 0;
    #17;
    rst = 1;
    #10;
    pc_next = 32'd4;
    @(posedge clk);#1;check(pc, 32'd4);
    #10;
    pc_next = 32'd8;
    @(posedge clk);#1;check(pc, 32'd8);
    #10;
    pc_next = 32'd8;
    rst = 0;
    @(posedge clk);#1;check(pc, 32'h0);
    

    if(errors == 0)begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule
