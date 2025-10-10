`include "constants.svh"

module igen_tb;
    parameter int DWIDTH=32;

    // Testbench signals
    logic [6:0] opcode_tb;
    logic [DWIDTH-1:0] insn_tb;
    logic [31:0] imm_tb;

    // Instantiate the igen module
    igen #( .DWIDTH(DWIDTH) ) uut (
        .opcode_i(opcode_tb),
        .insn_i(insn_tb),
        .imm_o(imm_tb)
    );

    // Test procedure
    initial begin
        // Test case 1: I-type instruction (e.g., ADDI)
        opcode_tb = 7'b0010011; // OPCODE_ITYPE
        insn_tb = 32'b000000000001_00000_000_00001_0010011; // ADDI x1, x0, 1
        #10;
        $display("Test 1 - I-type: imm = %h (expected: 00000001)", imm_tb);

        // Test case 2: S-type instruction (e.g., SW)
        opcode_tb = 7'b0100011; // OPCODE_STORE
        insn_tb = 32'b0000000_00010_00001_010_00000_0100011; // SW x2, 0(x1)
        #10;
        $display("Test 2 - S-type: imm = %h (expected: 00000000)", imm_tb);

        // Test case 3: B-type instruction (e.g., BEQ)
        opcode_tb = 7'b1100011; // OPCODE_BRANCH
        insn_tb = 32'b0000000_00010_00001_000_00000_1100011; // BEQ x1, x2, offset 0
        #10;
        $display("Test 3 - B-type: imm = %h (expected: 00000000)", imm_tb);

        // Test case 4: U-type instruction (e.g., LUI)
        opcode_tb = 7'b0110111; // OPCODE_LUI
        insn_tb = 32'b000000000001_00000_0110111; // LUI x0, 0x1000
        #10;
        $display("Test 4 - U-type: imm = %h (expected: 00001000)", imm_tb);

        // Test case 5: J-type instruction (e.g., JAL)
        opcode_tb = 7'b1101111; // OPCODE_JAL
        insn_tb = 32'b000000000001_00000_1101111; // JAL x0, offset 0x1000
        #10;
        $display("Test 5 - J-type: imm = %h (expected: 00001000)", imm_tb);

        // Finish simulation
        $finish;
    end

endmodule : igen_tb