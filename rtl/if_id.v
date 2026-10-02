`timescale 1ns/1ps
`include "definitions.vh"
module if_id(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,
    input wire [31:0] instruction_in,
    input wire [31:0] pc_in,
    output reg [31:0] instruction_out,
    output reg [31:0] pc_out
);

always @(posedge clk) begin
    if(rst == 0)begin
        instruction_out <= 32'b0;
        pc_out <= 32'b0;
    end else if (flush) begin 
        instruction_out <= 32'b0;
        pc_out <= 32'b0;
    end else if (stall) begin 
        
    end else begin 
        instruction_out <= instruction_in;
        pc_out <= pc_in;
    end
end
endmodule