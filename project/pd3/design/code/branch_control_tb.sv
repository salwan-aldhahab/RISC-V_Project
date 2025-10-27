`include "constants.svh"

module branch_control_tb;
    parameter int DWIDTH = 32;

    // Testbench signals - connecting to our branch control
    logic [6:0] opcode_tb;          // Instruction opcode to test
    logic [2:0] funct3_tb;          // Function 3 field
    logic [DWIDTH-1:0] rs1_tb;      // Register source 1 data
    logic [DWIDTH-1:0] rs2_tb;      // Register source 2 data
    logic breq_tb;                  // Branch equal output
    logic brlt_tb;                  // Branch less than output

    // Create an instance of our branch control under test
    branch_control #( .DWIDTH(DWIDTH) ) branch_control_dut (
        .opcode_i(opcode_tb),
        .funct3_i(funct3_tb),
        .rs1_i(rs1_tb),
        .rs2_i(rs2_tb),
        .breq_o(breq_tb),
        .brlt_o(brlt_tb)
    );

    // Run our test scenarios
    initial begin
        $display("=== Starting Branch Control Tests ===\n");

        // Test 1: BEQ - Branch if Equal (equal values)
        $display("Test 1: BEQ with equal values (rs1=5, rs2=5)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BEQ;
        rs1_tb = 32'd5;
        rs2_tb = 32'd5;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=1, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b1 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        // Test 2: BEQ - Branch if Equal (unequal values)
        $display("Test 2: BEQ with unequal values (rs1=5, rs2=3)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BEQ;
        rs1_tb = 32'd5;
        rs2_tb = 32'd3;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        // Test 3: BLT - Branch if Less Than (signed comparison, rs1 < rs2)
        $display("Test 3: BLT with rs1 < rs2 (rs1=3, rs2=5)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BLT;
        rs1_tb = 32'd3;
        rs2_tb = 32'd5;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=1)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b1) ? "PASS" : "FAIL");

        // Test 4: BLT - Branch if Less Than (signed comparison, rs1 > rs2)
        $display("Test 4: BLT with rs1 > rs2 (rs1=5, rs2=3)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BLT;
        rs1_tb = 32'd5;
        rs2_tb = 32'd3;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        // Test 5: BLT - Branch if Less Than (signed comparison with negative numbers)
        $display("Test 5: BLT with negative rs1 (rs1=-5, rs2=3)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BLT;
        rs1_tb = 32'hFFFFFFFB;  // -5 in two's complement
        rs2_tb = 32'd3;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=1)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b1) ? "PASS" : "FAIL");

        // Test 6: BLTU - Branch if Less Than Unsigned (rs1 < rs2)
        $display("Test 6: BLTU with rs1 < rs2 (rs1=3, rs2=5)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BLTU;
        rs1_tb = 32'd3;
        rs2_tb = 32'd5;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=1)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b1) ? "PASS" : "FAIL");

        // Test 7: BLTU - Branch if Less Than Unsigned (large unsigned vs small)
        $display("Test 7: BLTU with large unsigned (rs1=0xFFFFFFFB, rs2=3)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BLTU;
        rs1_tb = 32'hFFFFFFFB;  // Large unsigned number
        rs2_tb = 32'd3;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        // Test 8: BGE - Branch if Greater or Equal (rs1 >= rs2)
        $display("Test 8: BGE with rs1 >= rs2 (rs1=5, rs2=3)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BGE;
        rs1_tb = 32'd5;
        rs2_tb = 32'd3;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        // Test 9: Non-branch opcode (should output zeros)
        $display("Test 9: Non-branch opcode (I-type instruction)");
        opcode_tb = 7'b0010011;  // I-type opcode (not branch)
        funct3_tb = FUNCT3_BEQ;
        rs1_tb = 32'd5;
        rs2_tb = 32'd5;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=0, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b0 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        // Test 10: BNE - Branch if Not Equal (using equal check)
        $display("Test 10: BNE with equal values (rs1=5, rs2=5)");
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BNE;
        rs1_tb = 32'd5;
        rs2_tb = 32'd5;
        #10;
        $display("  Result: breq=%b, brlt=%b (Expected: breq=1, brlt=0)", breq_tb, brlt_tb);
        $display("  Status: %s\n", (breq_tb == 1'b1 && brlt_tb == 1'b0) ? "PASS" : "FAIL");

        $display("=== All tests completed ===");
        $finish;
    end

endmodule : branch_control_tb