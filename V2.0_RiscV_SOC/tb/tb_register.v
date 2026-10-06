`timescale 1ns/1ps
module tb_register();

reg clk, rst, write_enable;
reg [4:0] read_addr1, read_addr2, write_addr;
reg [31:0] write_data;
wire [31:0] read_data1, read_data2;

register dut (
    .clk(clk),
    .rst(rst),
    .write_enable(write_enable),
    .read_addr1(read_addr1),
    .read_addr2(read_addr2),
    .write_addr(write_addr),
    .write_data(write_data),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

initial clk = 0;
always #5 clk = ~clk;

integer errors = 0;
task check(input [31:0] a, input [31:0] b);
    if (a!== b)begin
        $display("FAIL got=%0h expected=%0h", a, b);
        errors = errors + 1;
    end else $display("PASS got=%0h expected=%0h", a, b);
endtask

initial begin
    $dumpfile("tb_register.vcd");
    $dumpvars(0, tb_register);

    rst = 0;
    #13;
    rst = 1;
    #10;
    //Test 1 - write 123 into x5
    write_enable = 1;
    write_addr = 5'd5;
    write_data = 32'd123;
    read_addr1 = 5'd5;
    read_addr2 = 5'd0;
    @(posedge clk);#1;check(read_data1, 32'd123);
    #10;
    //Test 2 - x0 remains 0 even if written
    write_addr = 5'b0;
    write_data = 32'd123;
    read_addr1 = 5'd0;
    @(posedge clk);#1;check(read_data1, 32'b0);
    #10;
    //Test 3 - write disable works
    write_enable = 0;
    write_addr = 5'd4;
    write_data = 32'd999;
    read_addr1 = 5'd4;
    @(posedge clk);#1;check(read_data1, 32'b0);
    //Test 4 - Simultaneous read x0 and x5
    read_addr1 = 5'b0;
    read_addr2 = 5'd5;
    @(posedge clk);#1;check(read_data1, 32'b0);check(read_data2, 32'd123);

    if(errors == 0)begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end
    $finish;
end
endmodule