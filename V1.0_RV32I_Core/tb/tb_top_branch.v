`timescale 1ns/1ps
`include "definitions.vh"
module tb_top_branch();

reg clk;
reg rst_a;
reg rst_b;
wire [3:0] sys_op_a;
wire [3:0] sys_op_b;
wire       illegal_a;
wire       illegal_b;

top #(
    .IMEM_INIT_FILE("programs/jal_test.hex")
) dut_a(
    .clk(clk),
    .rst(rst_a),
    .sys_op_out(sys_op_a),
    .illegal_out(illegal_a)
);

top #(
    .IMEM_INIT_FILE("programs/bne_test.hex")
) dut_b(
    .clk(clk),
    .rst(rst_b),
    .sys_op_out(sys_op_b),
    .illegal_out(illegal_b)
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
    $dumpfile("tb_top_branch.vcd");
    $dumpvars(0, tb_top_branch);

    //Hold both cores in reset at the start
    rst_a = 0;
    rst_b = 0;
    #17;

    //PHASE 1: run program A (JAL test) while B stays in reset
    rst_a = 1;
    wait (sys_op_a == `SYS_ECALL);
    #1;
    //Test 1 - x1 = 5 (addi executed)
    check(dut_a.regfile_dut.regs[1], 32'd5);
    //Test 2 - x2 = 0 (addi x2 was skipped by the JAL)
    check(dut_a.regfile_dut.regs[2], 32'd0);
    //Test 3 - x3 = 10 (instruction after the skipped one)
    check(dut_a.regfile_dut.regs[3], 32'd10);
    //Test 4 - no illegal instructions
    check(illegal_a, 1'b0);

    //PHASE 2: run program B (BNE loop test)
    rst_b = 1;
    wait (sys_op_b == `SYS_ECALL);
    #1;
    //Test 5 - x1 = 0 (loop decremented it to zero)
    check(dut_b.regfile_dut.regs[1], 32'd0);
    //Test 6 - x2 = 10 (reached after the loop exited)
    check(dut_b.regfile_dut.regs[2], 32'd10);
    //Test 7 - no illegal instructions
    check(illegal_b, 1'b0);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule