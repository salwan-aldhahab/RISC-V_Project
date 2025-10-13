`include "constants.svh"

module igen_tb;
    parameter int DWIDTH = 32;

    // Testbench signals - connecting to our immediate generator
    logic [6:0] opcode_tb;          // Instruction opcode to test
    logic [DWIDTH-1:0] insn_tb;     // Full 32-bit instruction
    logic [31:0] imm_tb;            // Generated immediate value

    // Create an instance of our immediate generator under test
    igen #( .DWIDTH(DWIDTH) ) immediate_generator_dut (
        .opcode_i(opcode_tb),
        .insn_i(insn_tb),
        .imm_o(imm_tb)
    );

    // Run our test scenarios
    initial begin
        $display("=== Starting Immediate Generator Tests ===\n");

        // Test 1: I-type instruction - Add Immediate
        // This tests loading a small positive immediate value
        $display("Test 1: I-type instruction (ADDI x1, x0, 1)");
        opcode_tb = 7'b0010011;                                    // I-type opcode
        insn_tb = 32'b000000000001_00000_000_00001_0010011;       // imm=1, rs1=x0, funct3=000, rd=x1
        #10;
        $display("  Result: imm = 0x%08h (Expected: 0x00000001)", imm_tb);
        $display("  Status: %s\n", (imm_tb == 32'h1) ? "PASS" : "FAIL");

        // Test 2: S-type instruction - Store Word
        // This tests how store instructions encode their immediate differently
        $display("Test 2: S-type instruction (SW x2, 0(x1))");
        opcode_tb = 7'b0100011;                                    // Store opcode
        insn_tb = 32'b0000000_00010_00001_010_00000_0100011;      // imm=0, rs2=x2, rs1=x1, funct3=010
        #10;
        $display("  Result: imm = 0x%08h (Expected: 0x00000000)", imm_tb);
        $display("  Status: %s\n", (imm_tb == 32'h0) ? "PASS" : "FAIL");

        // Test 3: B-type instruction - Branch if Equal
        // Branch instructions have a unique immediate encoding
        $display("Test 3: B-type instruction (BEQ x1, x2, +0)");
        opcode_tb = 7'b1100011;                                    // Branch opcode
        insn_tb = 32'b0000000_00010_00001_000_00000_1100011;      // imm=0, rs2=x2, rs1=x1, funct3=000
        #10;
        $display("  Result: imm = 0x%08h (Expected: 0x00000000)", imm_tb);
        $display("  Status: %s\n", (imm_tb == 32'h0) ? "PASS" : "FAIL");

        // Test 4: U-type instruction - Load Upper Immediate
        // Tests loading a large immediate into upper 20 bits
        $display("Test 4: U-type instruction (LUI x0, 0x1000)");
        opcode_tb = 7'b0110111;                                    // LUI opcode
        insn_tb = 32'b00000000000000000001_00000_0110111;         // imm=0x1000, rd=x0
        #10;
        $display("  Result: imm = 0x%08h (Expected: 0x00001000)", imm_tb);
        $display("  Status: %s\n", (imm_tb == 32'h1000) ? "PASS" : "FAIL");

        // Test 5: J-type instruction - Jump and Link
        // Jump instructions have their own immediate format
        $display("Test 5: J-type instruction (JAL x0, +0x1000)");
        opcode_tb = 7'b1101111;                                    // JAL opcode
        insn_tb = 32'b00000000000100000000_00000_1101111;         // imm=0x1000, rd=x0
        #10;
        $display("  Result: imm = 0x%08h (Expected: 0x00001000)", imm_tb);
        $display("  Status: %s\n", (imm_tb == 32'h1000) ? "PASS" : "FAIL");

        $display("=== All tests completed ===");
        $finish;
    end

endmodule : igen_tb