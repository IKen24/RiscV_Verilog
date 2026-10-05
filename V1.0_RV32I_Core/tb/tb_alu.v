`timescale 1ns/1ps
`include "definitions.vh"
module tb_alu();
reg [31:0] a, b;
reg [4:0] alu_control;
wire [31:0] result;
wire zero;


alu dut(
    .a(a),
    .b(b),
    .alu_control(alu_control),
    .result(result),
    .zero(zero)
);


integer errors = 0;
task check(input [31:0] a, input [31:0] b, input zf, input ezf);
    if ((a!== b)|(zf!==ezf))begin
        $display("FAIL result=%0h expected_result=%0h zero_flag=%0h expected_zero_flag=%0h", a, b, zf, ezf);
        errors = errors + 1;
    end else $display("PASS result=%0h expected_result=%0h zero_flag=%0h expected_zero_flag=%0h", a, b, zf, ezf);
endtask

initial begin
    $dumpfile("tb_alu.vcd");
    $dumpvars(0, tb_alu);

    //Test 1 - Addition
    a = 32'd5; b = 32'd3; alu_control = `ALU_ADD;
    #1;check(result, 32'd8, zero, 0);
    //Test 2 - Subtraction
    a = 32'd5; b = 32'd5; alu_control = `ALU_SUB;
    #1;check(result, 32'd0, zero, 1);
    //Test 3 - Logical AND
    a = 32'hF0F0; b = 32'h0F0F; alu_control = `ALU_AND;
    #1;check(result, 32'h0, zero, 1);
    //Test 4 - Logical OR
    a = 32'hF0F0; b = 32'h0F0F; alu_control = `ALU_OR;
    #1;check(result, 32'hFFFF, zero, 0);
    //Test 5 - Logical Exclusive OR
    a = 32'hAAAA; b = 32'hFFFF; alu_control = `ALU_XOR;
    #1;check(result, 32'h5555, zero, 0);
    //Test 6 - Set Less Than (signed)
    a = -32'sd1; b = 32'd1; alu_control = `ALU_SLT;
    #1;check(result, 1, zero, 0);
    //Test 7 - Set Less Than (unsigned)
    a = -32'sd10; b = 32'd7; alu_control = `ALU_SLTU;
    #1;check(result, 0, zero, 1);
    //Test 8 - Shift Left Logical
    a = 32'd1; b = 32'd4; alu_control = `ALU_SLL;
    #1;check(result, 32'd16, zero, 0);
    //Test 9 - Shift Right Logical
    a = 32'h80000000; b = 32'd1; alu_control = `ALU_SRL;
    #1;check(result, 32'h40000000, zero, 0);
    //Test 10 - Shift Right Arithmetic
    a = 32'h80000000; b = 32'd1; alu_control = `ALU_SRA;
    #1;check(result, 32'hC0000000, zero, 0);
    //Test 11 - Pass A
    a = 32'd50; alu_control = `ALU_PASS_A;
    #1;check(result, 32'd50, zero, 0);
    //Test 12 - Pass b
    b = 32'd70; alu_control = `ALU_PASS_B;
    #1;check(result, 32'd70, zero, 0);
    //Test 13 - Shift By 0 
    a = 32'd10; b = 32'd0; alu_control = `ALU_SLL;
    #1;check(result, 32'd10, zero, 0);
    //Test 14 - Shuft right 31
    a = 32'h80000000; b = 32'd31; alu_control = `ALU_SRA;
    #1;check(result, 32'hFFFFFFFF, zero, 0);
    

    if(errors == 0)begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end

    $finish;
end
endmodule