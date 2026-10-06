`timescale 1ns/1ps
`include "definitions.vh"
module  tb_immgen();

    reg [31:0] instruction;
    reg [2:0] imm_type;
    wire [31:0] immediate;

immgen dut(
    .instruction(instruction),
    .imm_type(imm_type),
    .immediate(immediate)
);

integer errors = 0;
task check(input [31:0] a, input [31:0] b);
    if ((a!== b))begin
        $display("FAIL result=%0h expected_result=%0h", a, b);
        errors = errors + 1;
    end else $display("PASS result=%0h expected_result=%0h", a, b);
endtask

initial begin
    $dumpfile("tb_immgen.vcd");
    $dumpvars(0, tb_immgen);
    //Test 1 - I-Type addi x1, x2, 5
    instruction = 32'h00510093; imm_type = `IMM_I;
    #1;check(immediate, 32'h5);
    //Test 2 - S-Type sw x1, 8(x2)
    instruction = 32'h00112423; imm_type = `IMM_S;
    #1;check(immediate, 32'h8);
    //Test 3 - B-Type beq x1, x2, 12
    instruction = 32'h00208663; imm_type = `IMM_B;
    #1;check(immediate, 32'hC);
    //Test 4 - U-Type lui x1, 0x12345
    instruction = 32'h123450B7; imm_type = `IMM_U;
    #1;check(immediate, 32'h12345000);
    //Test 5 - J-Type jal x1, 8
    instruction = 32'h008000EF; imm_type = `IMM_J;
    #1;check(immediate, 32'h8);
    //Test 6 - Negative I-Type addi x1, x2, -4
    instruction = 32'hFFC10093; imm_type = `IMM_I;
    #1;check(immediate, 32'hFFFFFFFC);
    //Test 7 - Negative S-Type sw x1, -4(x2)
    instruction = 32'hFE112E23; imm_type = `IMM_S;
    #1;check(immediate, 32'hFFFFFFFC);
    //Test 8 - Negative B-Type beq x1, x2, -8
    instruction = 32'hFE110CE3; imm_type = `IMM_B;
    #1;check(immediate, 32'hFFFFFFF8);
    //Test 9 - Negative J-Type jal x1, -4
    instruction = 32'hFFDFF0EF; imm_type = `IMM_J;
    #1;check(immediate, 32'hFFFFFFFC);
    //Test 10 - No Immediate
    instruction = 32'h00000033; imm_type = `IMM_NONE;
    #1;check(immediate, 32'h0);

    if(errors == 0)begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end

    $finish;
end
endmodule