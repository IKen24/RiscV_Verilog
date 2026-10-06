`timescale 1ns/1ps
`include "definitions.vh"
module tb_branch();

reg  [2:0]  funct3;
reg         alu_zero;
reg  [31:0] alu_result;
reg         branch;
reg         jump;
wire        branch_taken;

branch dut(
    .funct3(funct3),
    .alu_zero(alu_zero),
    .alu_result(alu_result),
    .branch(branch),
    .jump(jump),
    .branch_taken(branch_taken)
);

integer errors = 0;
task check(input a, input b);
    if (a !== b) begin
        $display("FAIL result=%0b expected_result=%0b", a, b);
        errors = errors + 1;
    end else $display("PASS result=%0b expected_result=%0b", a, b);
endtask

initial begin
    $dumpfile("tb_branch.vcd");
    $dumpvars(0, tb_branch);

    //Test 1 - neither branch nor jump: no redirect
    funct3 = 3'b000; alu_zero = 0; alu_result = 32'd0; branch = 0; jump = 0;
    #1;check(branch_taken, 1'b0);
    //Test 2 - jump: always taken
    funct3 = 3'b000; alu_zero = 0; alu_result = 32'd0; branch = 0; jump = 1;
    #1;check(branch_taken, 1'b1);
    //Test 3 - BEQ taken (alu_zero = 1)
    funct3 = `F3_BEQ; alu_zero = 1; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b1);
    //Test 4 - BEQ not taken (alu_zero = 0)
    funct3 = `F3_BEQ; alu_zero = 0; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b0);
    //Test 5 - BNE taken (alu_zero = 0)
    funct3 = `F3_BNE; alu_zero = 0; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b1);
    //Test 6 - BNE not taken (alu_zero = 1)
    funct3 = `F3_BNE; alu_zero = 1; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b0);
    //Test 7 - BLT taken (alu_result bit 0 = 1)
    funct3 = `F3_BLT; alu_zero = 0; alu_result = 32'd1; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b1);
    //Test 8 - BLT not taken (alu_result bit 0 = 0)
    funct3 = `F3_BLT; alu_zero = 0; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b0);
    //Test 9 - BGE taken (alu_result bit 0 = 0)
    funct3 = `F3_BGE; alu_zero = 0; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b1);
    //Test 10 - BGE not taken (alu_result bit 0 = 1)
    funct3 = `F3_BGE; alu_zero = 0; alu_result = 32'd1; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b0);
    //Test 11 - BLTU taken (alu_result bit 0 = 1)
    funct3 = `F3_BLTU; alu_zero = 0; alu_result = 32'd1; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b1);
    //Test 12 - BGEU taken (alu_result bit 0 = 0)
    funct3 = `F3_BGEU; alu_zero = 0; alu_result = 32'd0; branch = 1; jump = 0;
    #1;check(branch_taken, 1'b1);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule