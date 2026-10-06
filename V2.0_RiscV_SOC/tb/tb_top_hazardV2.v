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

// Diagnostic printout every 200 time units
initial begin
    #100;
    repeat (200) begin
        #20;
        $display("t=%0t pc=%h db=%b exR=%b exW=%b exA=%h exD=%h rawD=%h cyc=%b do=%h di=%h",
         $time,
         dut.core_dut.pc,
         dut.core_dut.dbus_state,
         dut.core_dut.ex_mem_mem_read,
         dut.core_dut.ex_mem_mem_write,
         dut.core_dut.ex_mem_alu_result,
         dut.core_dut.ex_mem_rs2_value,
         dut.core_dut.dmem_read_data_raw_reg,
         dut.core_dut.wb_dbus_cyc_o,
         dut.core_dut.wb_dbus_dat_o,
         dut.core_dut.wb_dbus_dat_i);
    end
end

always @(posedge clk) begin
    $strobe("t=%0t IF/ID=%h id_if_rs1=%b id_if_rs2=%b idR=%b idW=%b exR=%b exW=%b haz=%b fl=%b dbst=%b ibst=%b",
            $time,
            dut.core_dut.if_id_instruction,
            dut.core_dut.if_id_instruction[19:15],
            dut.core_dut.if_id_instruction[24:20],
            dut.core_dut.id_ex_mem_read,
            dut.core_dut.id_ex_mem_write,
            dut.core_dut.ex_mem_mem_read,
            dut.core_dut.ex_mem_mem_write,
            dut.core_dut.hazard_stall,
            dut.core_dut.flush_id_ex,
            dut.core_dut.dbus_stall,
            dut.core_dut.ibus_stall);
end

always @(posedge clk) begin
    if (dut.core_dut.ex_mem_mem_read | dut.core_dut.ex_mem_mem_write) begin
        $strobe("t=%0t MEMOP exR=%b exW=%b exA=%h exD=%h idR=%b idW=%b exmst=%b idxst=%b dbst=%b db=%b",
                $time,
                dut.core_dut.ex_mem_mem_read,
                dut.core_dut.ex_mem_mem_write,
                dut.core_dut.ex_mem_alu_result,
                dut.core_dut.ex_mem_rs2_value,
                dut.core_dut.id_ex_mem_read,
                dut.core_dut.id_ex_mem_write,
                dut.core_dut.ex_mem_dut.stall,
                dut.core_dut.id_ex_dut.stall,
                dut.core_dut.dbus_stall,
                dut.core_dut.dbus_state);
    end
end

always @(posedge clk) begin
    if (dut.core_dut.if_id_instruction == 32'h00000073)
        $display("t=%0t ECALL reached IF/ID", $time);
    if (dut.core_dut.id_ex_sys_op != 4'd0)
        $display("t=%0t ECALL reached ID/EX, sys_op=%h", $time, dut.core_dut.id_ex_sys_op);
    if (dut.core_dut.ex_mem_sys_op != 4'd0)
        $display("t=%0t ECALL reached EX/MEM, sys_op=%h", $time, dut.core_dut.ex_mem_sys_op);
    if (dut.core_dut.mem_wb_sys_op != 4'd0)
        $display("t=%0t ECALL reached MEM/WB, sys_op=%h", $time, dut.core_dut.mem_wb_sys_op);
end

always @(posedge clk) begin
    if (dut.core_dut.if_id_instruction === 32'h00000073)
        $display("t=%0t ECALL in IF/ID", $time);
    if (dut.core_dut.id_ex_sys_op === 4'd1)
        $display("t=%0t ECALL in ID/EX", $time);
    if (dut.core_dut.ex_mem_sys_op === 4'd1)
        $display("t=%0t ECALL in EX/MEM", $time);
    if (dut.core_dut.mem_wb_sys_op === 4'd1)
        $display("t=%0t ECALL in MEM/WB", $time);
    if (sys_op_out === 4'd1)
        $display("t=%0t ECALL on sys_op_out", $time);
end

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
