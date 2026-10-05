`timescale 1ns/1ps
`include "definitions.vh"
module  tb_decoder();

reg [31:0] instruction;

wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;

wire [4:0] alu_control;
wire alu_src;

wire reg_write;
wire mem_read;
wire mem_write;
wire [1:0] wb_sel;
wire branch;
wire jump;

wire [2:0] imm_type;
wire illegal;

wire        use_pc;
wire [3:0]  sys_op;

decoder dut(
    .instruction(instruction),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .alu_control(alu_control),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .wb_sel(wb_sel),
    .branch(branch),
    .jump(jump),
    .imm_type(imm_type),
    .illegal(illegal),
    .use_pc(use_pc),
    .sys_op(sys_op)
);

integer errors = 0;
task check(
    input [4:0] ers1, ers2, erd,
    input [4:0] ealu_control,
    input       ealu_src, ereg_write, emem_read, emem_write,
    input [1:0] ewb_sel,
    input       ebranch, ejump,
    input [2:0] eimm_type,
    input       eillegal, euse_pc,
    input [3:0] esys_op
);
    reg fail;
    begin
        fail = 0;
        if (rs1         !== ers1)         begin $display("FAIL rs1:         got=%0d expected=%0d", rs1, ers1);                 fail = 1; end
        if (rs2         !== ers2)         begin $display("FAIL rs2:         got=%0d expected=%0d", rs2, ers2);                 fail = 1; end
        if (rd          !== erd)          begin $display("FAIL rd:          got=%0d expected=%0d", rd, erd);                   fail = 1; end
        if (alu_control !== ealu_control) begin $display("FAIL alu_control: got=%0d expected=%0d", alu_control, ealu_control); fail = 1; end
        if (alu_src     !== ealu_src)     begin $display("FAIL alu_src:     got=%0b expected=%0b", alu_src, ealu_src);         fail = 1; end
        if (reg_write   !== ereg_write)   begin $display("FAIL reg_write:   got=%0b expected=%0b", reg_write, ereg_write);     fail = 1; end
        if (mem_read    !== emem_read)    begin $display("FAIL mem_read:    got=%0b expected=%0b", mem_read, emem_read);       fail = 1; end
        if (mem_write   !== emem_write)   begin $display("FAIL mem_write:   got=%0b expected=%0b", mem_write, emem_write);     fail = 1; end
        if (wb_sel      !== ewb_sel)      begin $display("FAIL wb_sel:      got=%0d expected=%0d", wb_sel, ewb_sel);           fail = 1; end
        if (branch      !== ebranch)      begin $display("FAIL branch:      got=%0b expected=%0b", branch, ebranch);           fail = 1; end
        if (jump        !== ejump)        begin $display("FAIL jump:        got=%0b expected=%0b", jump, ejump);               fail = 1; end
        if (imm_type    !== eimm_type)    begin $display("FAIL imm_type:    got=%0d expected=%0d", imm_type, eimm_type);       fail = 1; end
        if (illegal     !== eillegal)     begin $display("FAIL illegal:     got=%0b expected=%0b", illegal, eillegal);         fail = 1; end
        if (use_pc      !== euse_pc)      begin $display("FAIL use_pc:      got=%0b expected=%0b", use_pc, euse_pc);           fail = 1; end
        if (sys_op      !== esys_op)      begin $display("FAIL sys_op:      got=%0d expected=%0d", sys_op, esys_op);           fail = 1; end
        if (fail) errors = errors + 1;
        else $display("PASS");
    end
endtask

initial begin
    $dumpfile("tb_decoder.vcd");
    $dumpvars(0, tb_decoder);

    //Test 1 - OP_R: add x1, x2, x3
    instruction = 32'h003100B3;
    #1;check(5'd2, 5'd3, 5'd1, `ALU_ADD, 1'b0, 1'b1, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_NONE, 1'b0, 1'b0, `SYS_NONE);
    //Test 2 - OP_I: addi x4, x5, 0
    instruction = 32'h00028213;
    #1;check(5'd5, 5'd0, 5'd4, `ALU_ADD, 1'b1, 1'b1, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_I,    1'b0, 1'b0, `SYS_NONE);
    //Test 3 - OP_LOAD: lw x6, 0(x7)
    instruction = 32'h0003A303;
    #1;check(5'd7, 5'd0, 5'd6, `ALU_ADD, 1'b1, 1'b1, 1'b1, 1'b0, `WB_MEM, 1'b0, 1'b0, `IMM_I,    1'b0, 1'b0, `SYS_NONE);
    //Test 4 - OP_STORE: sw x8, 0(x9)
    instruction = 32'h0084A023;
    #1;check(5'd9, 5'd8, 5'd0, `ALU_ADD, 1'b1, 1'b0, 1'b0, 1'b1, `WB_ALU, 1'b0, 1'b0, `IMM_S,    1'b0, 1'b0, `SYS_NONE);
    //Test 5 - OP_BRANCH: beq x10, x11, 0
    instruction = 32'h00B50063;
    #1;check(5'd10, 5'd11, 5'd0, `ALU_SUB, 1'b0, 1'b0, 1'b0, 1'b0, `WB_ALU, 1'b1, 1'b0, `IMM_B,    1'b0, 1'b0, `SYS_NONE);
    //Test 6 - OP_JAL: jal x1, 8
    instruction = 32'h008000EF;
    #1;check(5'd0, 5'd8, 5'd1, `ALU_ADD, 1'b0, 1'b1, 1'b0, 1'b0, `WB_PC4, 1'b0, 1'b1, `IMM_J,    1'b0, 1'b0, `SYS_NONE);
    //Test 7 - OP_JALR: jalr x1, x2, 4
    instruction = 32'h000100E7;
    #1;check(5'd2, 5'd0, 5'd1, `ALU_ADD, 1'b1, 1'b1, 1'b0, 1'b0, `WB_PC4, 1'b0, 1'b1, `IMM_I,    1'b0, 1'b0, `SYS_NONE);
    //Test 8 - OP_LUI: lui x12, 0x12345
    instruction = 32'h12345637;
    #1;check(5'd8, 5'd3, 5'd12, `ALU_PASS_B, 1'b1, 1'b1, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_U, 1'b0, 1'b0, `SYS_NONE);
    //Test 9 - OP_AUIPC: auipc x13, 0x1000
    instruction = 32'h00001697;
    #1;check(5'd0, 5'd0, 5'd13, `ALU_ADD, 1'b1, 1'b1, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_U,  1'b0, 1'b1, `SYS_NONE);
    //Test 10 - OP_MISC_MEM: fence
    instruction = 32'h0000000F;
    #1;check(5'd0, 5'd0, 5'd0, `ALU_ADD, 1'b0, 1'b0, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_NONE, 1'b0, 1'b0, `SYS_NONE);
    //Test 11 - OP_SYSTEM: ecall
    instruction = 32'h00000073;
    #1;check(5'd0, 5'd0, 5'd0, `ALU_ADD, 1'b0, 1'b0, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_NONE, 1'b0, 1'b0, `SYS_ECALL);
    //Test 12 - Illegal instruction
    instruction = 32'hFFFFFFFF;
    #1;check(5'd31, 5'd31, 5'd31, `ALU_ADD, 1'b0, 1'b0, 1'b0, 1'b0, `WB_ALU, 1'b0, 1'b0, `IMM_NONE, 1'b1, 1'b0, `SYS_NONE);


    if(errors == 0)begin
        $display("All Tests Passed");
    end else begin
        $display("%0d Tests Failed", errors);
    end

    $finish;
end
endmodule