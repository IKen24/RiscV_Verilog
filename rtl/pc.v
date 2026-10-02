`timescale 1ns/1ps
`include "definitions.vh"
module pc (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [31:0] pc_next,
    output reg [31:0] pc
);

always @(posedge clk) begin
    if(rst == 0)begin
        pc <= 32'b0;
    end else if(stall)begin 
        
    end else begin
        pc <= pc_next;
    end
    
end
    
endmodule