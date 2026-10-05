`timescale 1ns/1ps
`include "definitions.vh"
module tb_dmem();

reg         clk;
reg         mem_read;
reg         mem_write;
reg  [2:0]  funct3;
reg  [31:0] address;
reg  [31:0] write_data;
wire [31:0] read_data;

dmem dut(
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .funct3(funct3),
    .address(address),
    .write_data(write_data),
    .read_data(read_data)
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
    $dumpfile("tb_dmem.vcd");
    $dumpvars(0, tb_dmem);

    mem_read = 0; mem_write = 0; funct3 = 0; address = 0; write_data = 0;

    //Test 1 - SW then LW: write 0xDEADBEEF to address 0, read it back
    mem_write = 1; mem_read = 0; funct3 = `F3_SW; address = 32'd0; write_data = 32'hDEADBEEF;
    @(posedge clk);#1;
    mem_write = 0; mem_read = 1; funct3 = `F3_LW;
    #1;check(read_data, 32'hDEADBEEF);
    //Test 2a - SB 0x80 at address 4, LB sign-extends
    mem_write = 1; mem_read = 0; funct3 = `F3_SB; address = 32'd4; write_data = 32'h00000080;
    @(posedge clk);#1;
    mem_write = 0; mem_read = 1; funct3 = `F3_LB;
    #1;check(read_data, 32'hFFFFFF80);
    //Test 2b - LBU zero-extends the same byte
    funct3 = `F3_LBU;
    #1;check(read_data, 32'h00000080);
    //Test 3a - SH 0x8000 at address 8, LH sign-extends
    mem_write = 1; mem_read = 0; funct3 = `F3_SH; address = 32'd8; write_data = 32'h00008000;
    @(posedge clk);#1;
    mem_write = 0; mem_read = 1; funct3 = `F3_LH;
    #1;check(read_data, 32'hFFFF8000);
    //Test 3b - LHU zero-extends the same halfword
    funct3 = `F3_LHU;
    #1;check(read_data, 32'h00008000);
    //Test 4 - SW 0xDDCCBBAA at address 12, read each byte with LBU
    mem_write = 1; mem_read = 0; funct3 = `F3_SW; address = 32'd12; write_data = 32'hDDCCBBAA;
    @(posedge clk);#1;
    mem_write = 0; mem_read = 1; funct3 = `F3_LBU;
    address = 32'd12; #1;check(read_data, 32'h000000AA);
    address = 32'd13; #1;check(read_data, 32'h000000BB);
    address = 32'd14; #1;check(read_data, 32'h000000CC);
    address = 32'd15; #1;check(read_data, 32'h000000DD);
    //Test 5 - two independent word writes at different addresses
    mem_write = 1; mem_read = 0; funct3 = `F3_SW; address = 32'd16; write_data = 32'h11111111;
    @(posedge clk);#1;
    mem_write = 1; mem_read = 0; funct3 = `F3_SW; address = 32'd20; write_data = 32'h22222222;
    @(posedge clk);#1;
    mem_write = 0; mem_read = 1; funct3 = `F3_LW;
    address = 32'd16; #1;check(read_data, 32'h11111111);
    address = 32'd20; #1;check(read_data, 32'h22222222);

    if (errors == 0) begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule