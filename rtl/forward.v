`timescale 1ns/1ps
`include "definitions.vh"
module forward(
    input wire ex_mem_reg_write,
    input wire [4:0] ex_mem_rd_addr,

    input wire mem_wb_reg_write,
    input wire [4:0] mem_wb_rd_addr,

    input wire [4:0] id_ex_rs1_addr,
    input wire [4:0] id_ex_rs2_addr,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

always @(*) begin
    forward_a = `FW_NONE;
    forward_b = `FW_NONE;

    if((ex_mem_reg_write == 1) && (ex_mem_rd_addr !== 0) && (ex_mem_rd_addr == id_ex_rs1_addr))begin
        forward_a = `FW_MEM;
    end else if((mem_wb_reg_write == 1) && (mem_wb_rd_addr !== 0) && (mem_wb_rd_addr == id_ex_rs1_addr))begin
        forward_a = `FW_WB;
    end else begin forward_a = `FW_NONE; end

    if((ex_mem_reg_write == 1) && (ex_mem_rd_addr !== 0) && (ex_mem_rd_addr == id_ex_rs2_addr))begin
        forward_b = `FW_MEM;
    end else if((mem_wb_reg_write == 1) && (mem_wb_rd_addr !== 0) && (mem_wb_rd_addr == id_ex_rs2_addr))begin
        forward_b = `FW_WB;
    end else begin forward_b = `FW_NONE; end

end
endmodule