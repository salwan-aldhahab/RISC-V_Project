`include "constants.svh"

module execute_tb;
    parameter int DWIDTH = 32;
    parameter int AWIDTH = 32;

    // Testbench signals - connecting to our ALU
    logic [AWIDTH-1:0] pc_tb;       // Program counter
    logic [DWIDTH-1:0] rs1_tb;      // Register source 1 data
    logic [DWIDTH-1:0] rs2_tb;      // Register source 2 data
    logic [DWIDTH-1:0] imm_tb;      // Immediate value
    logic [6:0] opcode_tb;          // Instruction opcode
    logic [2:0] funct3_tb;          // Function 3 field
    logic [6:0] funct7_tb;          // Function 7 field
    logic [DWIDTH-1:0] res_tb;      // ALU result output
    logic brtaken_tb;               // Branch taken output

    // Test counters
    int pass_count = 0;
    int fail_count = 0;
    int total_tests = 0;

    // Create an instance of our ALU under test
    alu #( 
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) alu_dut (
        .pc_i(pc_tb),
        .rs1_i(rs1_tb),
        .rs2_i(rs2_tb),
        .imm_i(imm_tb),
        .opcode_i(opcode_tb),
        .funct3_i(funct3_tb),
        .funct7_i(funct7_tb),
        .res_o(res_tb),
        .brtaken_o(brtaken_tb)
    );

    // Run our test scenarios
    initial begin
        $display("=== Starting ALU (Execute) Tests ===\n");

        // Test 1: R-type ADD instruction
        total_tests++;
        $display("Test 1: R-type ADD (rs1=10, rs2=5)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd10;
        rs2_tb = 32'd5;
        imm_tb = 32'd0;
        opcode_tb = OPCODE_RTYPE;
        funct3_tb = FUNCT3_ADD_SUB;
        funct7_tb = 7'b0000000;  // ADD (not SUB)
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x0000000F, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'd15 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 2: R-type SUB instruction
        total_tests++;
        $display("Test 2: R-type SUB (rs1=10, rs2=3)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd10;
        rs2_tb = 32'd3;
        imm_tb = 32'd0;
        opcode_tb = OPCODE_RTYPE;
        funct3_tb = FUNCT3_ADD_SUB;
        funct7_tb = FUNCT7_SUB;  // SUB
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00000007, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'd7 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 3: I-type ADDI instruction
        total_tests++;
        $display("Test 3: I-type ADDI (rs1=10, imm=20)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd10;
        rs2_tb = 32'd0;
        imm_tb = 32'd20;
        opcode_tb = OPCODE_ITYPE;
        funct3_tb = FUNCT3_ADD_SUB;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x0000001E, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'd30 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 4: Load instruction (address calculation)
        total_tests++;
        $display("Test 4: LOAD (rs1=0x1000, imm=0x10)");
        pc_tb = 32'h1000;
        rs1_tb = 32'h1000;
        rs2_tb = 32'd0;
        imm_tb = 32'h10;
        opcode_tb = OPCODE_LOAD;
        funct3_tb = FUNCT3_LW;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00001010, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'h1010 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 5: Store instruction (address calculation)
        total_tests++;
        $display("Test 5: STORE (rs1=0x2000, imm=0x4)");
        pc_tb = 32'h1000;
        rs1_tb = 32'h2000;
        rs2_tb = 32'hDEADBEEF;
        imm_tb = 32'h4;
        opcode_tb = OPCODE_STORE;
        funct3_tb = FUNCT3_SW;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00002004, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'h2004 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 6: Branch BEQ taken (equal values)
        total_tests++;
        $display("Test 6: BEQ taken (rs1=5, rs2=5, pc=0x1000, imm=0x8)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd5;
        rs2_tb = 32'd5;
        imm_tb = 32'h8;
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BEQ;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00001008, brtaken=1)", res_tb, brtaken_tb);
        if (res_tb == 32'h1008 && brtaken_tb == 1'b1) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 7: Branch BEQ not taken (unequal values)
        total_tests++;
        $display("Test 7: BEQ not taken (rs1=5, rs2=3, pc=0x1000, imm=0x8)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd5;
        rs2_tb = 32'd3;
        imm_tb = 32'h8;
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BEQ;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00001008, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'h1008 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 8: Branch BLT taken (rs1 < rs2)
        total_tests++;
        $display("Test 8: BLT taken (rs1=3, rs2=7, pc=0x1000, imm=0xC)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd3;
        rs2_tb = 32'd7;
        imm_tb = 32'hC;
        opcode_tb = OPCODE_BRANCH;
        funct3_tb = FUNCT3_BLT;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x0000100C, brtaken=1)", res_tb, brtaken_tb);
        if (res_tb == 32'h100C && brtaken_tb == 1'b1) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 9: JAL instruction
        total_tests++;
        $display("Test 9: JAL (pc=0x1000, imm=0x100)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd0;
        rs2_tb = 32'd0;
        imm_tb = 32'h100;
        opcode_tb = OPCODE_JAL;
        funct3_tb = 3'b000;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00001100, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'h1100 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 10: LUI instruction
        total_tests++;
        $display("Test 10: LUI (imm=0x12345000)");
        pc_tb = 32'h1000;
        rs1_tb = 32'd0;
        rs2_tb = 32'd0;
        imm_tb = 32'h12345000;
        opcode_tb = OPCODE_LUI;
        funct3_tb = 3'b000;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x12345000, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'h12345000 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 11: R-type XOR instruction
        total_tests++;
        $display("Test 11: R-type XOR (rs1=0xF0F0F0F0, rs2=0x0F0F0F0F)");
        pc_tb = 32'h1000;
        rs1_tb = 32'hF0F0F0F0;
        rs2_tb = 32'h0F0F0F0F;
        imm_tb = 32'd0;
        opcode_tb = OPCODE_RTYPE;
        funct3_tb = FUNCT3_XOR;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0xFFFFFFFF, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'hFFFFFFFF && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 12: R-type SLT instruction (signed comparison)
        total_tests++;
        $display("Test 12: R-type SLT (rs1=-5, rs2=3)");
        pc_tb = 32'h1000;
        rs1_tb = 32'hFFFFFFFB;  // -5 in two's complement
        rs2_tb = 32'd3;
        imm_tb = 32'd0;
        opcode_tb = OPCODE_RTYPE;
        funct3_tb = FUNCT3_SLT;
        funct7_tb = 7'b0000000;
        #10;
        $display("  Result: res=0x%08h, brtaken=%b (Expected: res=0x00000001, brtaken=0)", res_tb, brtaken_tb);
        if (res_tb == 32'd1 && brtaken_tb == 1'b0) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Display final results
        $display("=== Test Summary ===");
        $display("Total Tests: %0d", total_tests);
        $display("Tests Passed: %0d", pass_count);
        $display("Tests Failed: %0d", fail_count);
        $display("Pass Rate: %0.1f%%", (real'(pass_count) / real'(total_tests)) * 100.0);
        
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("%0d test(s) failed. Check the implementation.", fail_count);
        end
        
        $display("=== All tests completed ===");
        $finish;
    end

endmodule : execute_tb