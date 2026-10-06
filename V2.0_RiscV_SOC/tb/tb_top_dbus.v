`timescale 1ns/1ps
`include "definitions.vh"
module tb_top_dbus();

reg clk;
reg rst;
wire [3:0] sys_op_out;
wire       illegal_out;

soc_top #(
    .IMEM_INIT_FILE("programs/dbus_test.hex")
) dut(
    .clk(clk),
    .rst(rst),
    .sys_op_out(sys_op_out),
    .illegal_out(illegal_out)
);

initial clk = 0;
always #5 clk = ~clk;

// Global timeout counter
integer cycle_count = 0;
always @(posedge clk) begin
    cycle_count = cycle_count + 1;
    if (cycle_count > 200) begin
        $display("TIMEOUT after 200 cycles");
        $display("Final state:");
        $display("  pc           = %h", dut.core_dut.pc);
        $display("  ibus_state   = %b", dut.core_dut.ibus_state);
        $display("  dbus_state   = %b", dut.core_dut.dbus_state);
        $display("  stall        = %b", dut.core_dut.stall);
        $display("  hazard_stall = %b", dut.core_dut.hazard_stall);
        $display("  ibus_stall   = %b", dut.core_dut.ibus_stall);
        $display("  dbus_stall   = %b", dut.core_dut.dbus_stall);
        $display("  exR          = %b", dut.core_dut.ex_mem_mem_read);
        $display("  exW          = %b", dut.core_dut.ex_mem_mem_write);
        $display("  exA          = %h", dut.core_dut.ex_mem_alu_result);
        $display("  idR          = %b", dut.core_dut.id_ex_mem_read);
        $display("  idW          = %b", dut.core_dut.id_ex_mem_write);
        $display("  sys_op_out   = %h", sys_op_out);
        $finish;
    end
end

// Event-driven diagnostic: only print when something changes
reg [31:0] last_pc;
reg [1:0]  last_ibs;
reg [1:0]  last_dbs;
reg        last_exR, last_exW;

always @(posedge clk) begin
    if (dut.core_dut.pc != last_pc ||
        dut.core_dut.ibus_state != last_ibs ||
        dut.core_dut.dbus_state != last_dbs ||
        dut.core_dut.ex_mem_mem_read != last_exR ||
        dut.core_dut.ex_mem_mem_write != last_exW) begin

        $display("t=%0t pc=%h ibs=%b dbs=%b exR=%b exW=%b exA=%h exD=%h rawD=%h stall=%b haz=%b ibst=%b dbst=%b",
                 $time,
                 dut.core_dut.pc,
                 dut.core_dut.ibus_state,
                 dut.core_dut.dbus_state,
                 dut.core_dut.ex_mem_mem_read,
                 dut.core_dut.ex_mem_mem_write,
                 dut.core_dut.ex_mem_alu_result,
                 dut.core_dut.ex_mem_rs2_value,
                 dut.core_dut.dmem_read_data_raw_reg,
                 dut.core_dut.stall,
                 dut.core_dut.hazard_stall,
                 dut.core_dut.ibus_stall,
                 dut.core_dut.dbus_stall);

        last_pc  = dut.core_dut.pc;
        last_ibs = dut.core_dut.ibus_state;
        last_dbs = dut.core_dut.dbus_state;
        last_exR = dut.core_dut.ex_mem_mem_read;
        last_exW = dut.core_dut.ex_mem_mem_write;
    end
end

integer errors = 0;
task check(input [31:0] a, input [31:0] b);
    if (a !== b) begin
        $display("FAIL result=%0h expected_result=%0h", a, b);
        errors = errors + 1;
    end else $display("PASS result=%0h expected_result=%0h", a, b);
endtask

initial begin
    $dumpfile("tb_top_dbus.vcd");
    $dumpvars(0, tb_top_dbus);

    rst = 0;
    #17;
    check(dut.core_dut.pc, 32'h0);

    rst = 1;
    @(posedge clk);

    // Do not block on the ECALL. Wait up to 180 cycles for it to arrive.
    fork
        begin
            wait (sys_op_out == `SYS_ECALL);
            #1;
            check(dut.core_dut.regfile_dut.regs[1], 32'd5);
            check(dut.core_dut.regfile_dut.regs[2], 32'd5);
            check(illegal_out, 1'b0);
            check(dut.core_dut.regfile_dut.regs[0], 32'd0);

            if (errors == 0) begin
                $display("All Tests Passed");
            end else begin
                $display("%0d Tests Failed", errors);
            end
            $finish;
        end
        begin
            #2000;  // 200 cycles at 10ns per cycle
            $display("ECALL never arrived within the timeout");
            $finish;
        end
    join
end
endmodule