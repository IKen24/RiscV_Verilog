`timescale 1ns/1ps
`include "definitions.vh"
module tb_wb_imem_slave();

reg         clk;
reg         rst;
reg  [31:0] wb_adr_i;
reg         wb_cyc_i;
reg         wb_stb_i;
wire [31:0] wb_dat_o;
wire        wb_ack_o;

wb_imem_slave #(
    .DEPTH(256),
    .INIT_FILE("programs/pipeline_test.hex"),
    .LATENCY(3)
) dut(
    .clk(clk),
    .rst(rst),
    .wb_adr_i(wb_adr_i),
    .wb_dat_o(wb_dat_o),
    .wb_cyc_i(wb_cyc_i),
    .wb_stb_i(wb_stb_i),
    .wb_ack_o(wb_ack_o)
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
    $dumpfile("tb_wb_imem_slave.vcd");
    $dumpvars(0, tb_wb_imem_slave);

    //Hold reset, bus idle
    rst = 0;
    wb_adr_i = 32'd0;
    wb_cyc_i = 0;
    wb_stb_i = 0;
    #17;
    rst = 1;
    @(posedge clk);

    //Test 1 - idle: no request, ack should stay low
    #20;
    check(wb_ack_o, 1'b0);

    //Test 2 - read address 0: addi x1, x0, 5
    wb_adr_i = 32'd0; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'h00500093);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);
    //Test 3 - read address 4: addi x2, x0, 7
    wb_adr_i = 32'd4; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'h00700113);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 4 - read address 8: addi x3, x0, 9
    wb_adr_i = 32'd8; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'h00900193);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 5 - read address 12: addi x4, x0, 11
    wb_adr_i = 32'd12; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'h00B00213);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 6 - read address 16: ecall
    wb_adr_i = 32'd16; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'h00000073);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 7 - ack stays low when no request
    check(wb_ack_o, 1'b0);

    //Test 8 - reset mid-transaction
    wb_adr_i = 32'd0; wb_cyc_i = 1; wb_stb_i = 1;
    @(posedge clk);
    rst = 0;
    @(posedge clk);#1;
    check(wb_ack_o, 1'b0);
    rst = 1;
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule