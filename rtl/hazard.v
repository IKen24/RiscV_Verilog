/*
// Module:      hazard
// File:        rtl/hazard.v
// Description: The hazard detection unit. Forwarding handles almost every
//              case where one instruction needs a value another instruction
//              has not finished producing. There is one case it cannot fix:
//              a load followed immediately by an instruction that uses the
//              loaded value.
//
//              Why forwarding fails here: a load's value does not exist
//              until the end of the Memory stage. Forwarding from EX/MEM or
//              MEM/WB grabs a value that is already sitting in a pipeline
//              register. But during the cycle the load is in Memory, its
//              result is still being produced, not yet stored anywhere. By
//              the time it lands in MEM/WB, the dependent instruction has
//              already passed through Execute. It is one cycle too late.
//
//              The fix is to pause. When this module sees a load in the
//              Execute stage whose destination register matches a source
//              register of the instruction in Decode, it raises the stall
//              signal for one cycle. The pipeline freezes: the PC holds, the
//              IF/ID register holds, and a bubble (a do-nothing instruction)
//              is inserted into ID/EX. On the next cycle, the load's value
//              has reached MEM/WB, forwarding can deliver it, and the
//              pipeline resumes normally.
//
//              The cost is one wasted cycle per load-use pair. Rare enough
//              that it barely matters in practice.
//
//              Register x0 is excluded from the comparison, same reason as
//              in the forwarding unit: writes to x0 are ignored, so there is
//              nothing to wait for.
//
//              The module has no clock and no reset. It is pure combinational
//              logic: the stall decision must be ready in the same cycle it
//              is needed.
*/

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