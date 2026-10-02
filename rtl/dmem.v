`timescale 1ns/1ps
`include "definitions.vh"
module dmem #(parameter DEPTH = 256)(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [2:0] funct3,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

reg [7:0] mem [0:DEPTH - 1];

always @(posedge clk)begin
    if(mem_write)begin
        case (funct3)
            `F3_SB: mem[address] <= write_data[7:0];
            `F3_SH: begin mem[address] <= write_data[7:0]; mem[address + 1] <= write_data[15:8];  end
            `F3_SW: begin mem[address] <= write_data[7:0]; mem[address + 1] <= write_data[15:8]; mem[address + 2] <= write_data[23:16]; mem[address + 3] <= write_data[31:24]; end 
            default: ; 
        endcase
    end
end

always @(*)begin
    if(mem_read)begin
        case(funct3)
        `F3_LB: read_data = {{24{mem[address][7]}},mem[address]};
        `F3_LH: read_data = {{16{mem[address + 1][7]}}, mem[address + 1], mem[address]};
        `F3_LW: read_data = {mem[address + 3], mem[address + 2], mem[address + 1], mem[address]};
        `F3_LBU:read_data = {24'b0,mem[address]};
        `F3_LHU:read_data = {16'b0, mem[address + 1], mem[address]};
        default: read_data = 32'b0;
        endcase
    end else begin read_data = 32'b0; end

end
endmodule