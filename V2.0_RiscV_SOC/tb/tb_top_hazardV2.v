`timescale 1ns/1ps
`include "definitions.vh"
module tb_top_hazardV2();

reg clk;
reg rst;
wire [3:0] sys_op_out;
wire       illegal_out;

soc_top #(
    .IMEM_INIT_FILE("programs/hazard_test.hex")
) dut(
    .clk(clk),
    .rst(rst),
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
    $dumpfile("tb_top_hazardV2.vcd");
    $dumpvars(0, tb_top_hazardV2);

    //Test 1 - hold reset, PC should be at 0
    rst = 0;
    #17;
    // FIX: Added core_dut to the path
    check(dut.core_dut.pc, 32'h0);
    
    //Test 2 - release reset, let the program run
    rst = 1;
    @(posedge clk);
    
    //Test 3 - wait for ecall to reach the MEM/WB stage
    wait (sys_op_out == `SYS_ECALL);
    #1;
    
    //Test 4 - x1 = 5 (addi result)
    // FIX: Added core_dut to the path
    check(dut.core_dut.regfile_dut.regs[1], 32'd5);
    
    //Test 5 - x2 = 5 (loaded from memory at address 0)
    check(dut.core_dut.regfile_dut.regs[2], 32'd5);
    
    //Test 6 - x3 = 6 (proves the load-use hazard was handled correctly)
    check(dut.core_dut.regfile_dut.regs[3], 32'd6);
    
    //Test 7 - no illegal instructions should have occurred
    check(illegal_out, 1'b0);
    
    //Test 8 - x0 must still be zero
    check(dut.core_dut.regfile_dut.regs[0], 32'd0);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule`timescale 1ns/1ps
