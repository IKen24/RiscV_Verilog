`timescale 1ns/1ps
`include "definitions.vh"

module hazard(
    input wire id_ex_mem_read,
    input wire [4:0] id_ex_rd_addr,
    input wire [4:0] if_id_rs1_addr,
    input wire [4:0] if_id_rs2_addr,
    output reg stall
);

always @(*) begin
    stall = 1'b0;
    if((id_ex_mem_read == 1) && (id_ex_rd_addr !== 0) && ((id_ex_rd_addr == if_id_rs1_addr)||(id_ex_rd_addr == if_id_rs2_addr)))begin
        stall = 1'b1;
    end
end
endmodule