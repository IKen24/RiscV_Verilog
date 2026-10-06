`timescale 1ns/1ps
`include "definitions.vh"
module tb_wb_dmem_slave();

reg         clk;
reg         rst;
reg  [31:0] wb_adr_i;
reg  [31:0] wb_dat_i;
reg         wb_we_i;
reg  [3:0]  wb_sel_i;
reg         wb_cyc_i;
reg         wb_stb_i;
wire [31:0] wb_dat_o;
wire        wb_ack_o;

wb_dmem_slave #(
    .DEPTH(256),
    .LATENCY(3)
) dut(
    .clk(clk),
    .rst(rst),
    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_we_i(wb_we_i),
    .wb_sel_i(wb_sel_i),
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
    $dumpfile("tb_wb_dmem_slave.vcd");
    $dumpvars(0, tb_wb_dmem_slave);

    //Hold reset, bus idle
    rst = 0;
    wb_adr_i = 32'd0;
    wb_dat_i = 32'd0;
    wb_we_i = 0;
    wb_sel_i = 4'b1111;
    wb_cyc_i = 0;
    wb_stb_i = 0;
    #17;
    rst = 1;
    @(posedge clk);

    //Test 1 - word write 0xDEADBEEF to address 0
    wb_adr_i = 32'd0; wb_dat_i = 32'hDEADBEEF; wb_we_i = 1; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 2 - word read address 0, expect 0xDEADBEEF
    wb_adr_i = 32'd0; wb_we_i = 0; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'hDEADBEEF);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 3 - byte write 0xAA at address 0
    wb_adr_i = 32'd0; wb_dat_i = 32'h000000AA; wb_we_i = 1; wb_sel_i = 4'b0001; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 4 - word read address 0, expect 0xDEADBEAA (only byte 0 changed)
    wb_adr_i = 32'd0; wb_we_i = 0; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'hDEADBEAA);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 5 - byte write 0xBB at address 1
    wb_adr_i = 32'd1; wb_dat_i = 32'h000000BB; wb_we_i = 1; wb_sel_i = 4'b0001; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 6 - word read address 0, expect 0xDEADBBAA (byte 1 changed)
    wb_adr_i = 32'd0; wb_we_i = 0; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'hDEADBBAA);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 7 - initialize word at address 4
    wb_adr_i = 32'd4; wb_dat_i = 32'hAAAA5555; wb_we_i = 1; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 8 - halfword write 0x1234 at address 4, bytes 0 and 1 of the word
    wb_adr_i = 32'd4; wb_dat_i = 32'h00001234; wb_we_i = 1; wb_sel_i = 4'b0011; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 9 - word read address 4, expect 0xAAAA1234
    wb_adr_i = 32'd4; wb_we_i = 0; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'hAAAA1234);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 10 - independent word write at address 8
    wb_adr_i = 32'd8; wb_dat_i = 32'hCAFEBABE; wb_we_i = 1; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 11 - read back address 8, expect 0xCAFEBABE
    wb_adr_i = 32'd8; wb_we_i = 0; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'hCAFEBABE);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 12 - confirm address 0 unchanged by address 8 write
    wb_adr_i = 32'd0; wb_we_i = 0; wb_sel_i = 4'b1111; wb_cyc_i = 1; wb_stb_i = 1;
    wait (wb_ack_o == 1); #1;
    check(wb_dat_o, 32'hDEADBBAA);
    wb_cyc_i = 0; wb_stb_i = 0;
    wait (wb_ack_o == 0);
    @(posedge clk);

    //Test 13 - ack stays low when no request
    #20;
    check(wb_ack_o, 1'b0);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule