`include "constants.svh"

module decode_tb;
    parameter int DWIDTH = 32;
    parameter int AWIDTH = 32;

    // Testbench signals
    logic [DWIDTH-1:0] insn_i;
    logic [AWIDTH-1:0] pc_i;

    logic [AWIDTH-1:0] pc_o;
    logic [DWIDTH-1:0] insn_o;
    logic [6:0] opcode_o;
    logic [4:0] rd_o;
    logic [4:0] rs1_o;
    logic [4:0] rs2_o;
    logic [6:0] funct7_o;
    logic [2:0] funct3_o;
    logic [4:0] shamt_o;  // shift amount
    logic [DWIDTH-1:0] imm_o;

    // Instantiate the decode module
    decode #( .DWIDTH(DWIDTH), .AWIDTH(AWIDTH) ) dut (
        .clk(),
        .rst(),
        .insn_i(insn_i),
        .pc_i(pc_i),
        .pc_o(pc_o),
        .insn_o(insn_o),
        .opcode_o(opcode_o),
        .rd_o(rd_o),
        .rs1_o(rs1_o),
        .rs2_o(rs2_o),
        .funct7_o(funct7_o),
        .funct3_o(funct3_o),
        .shamt_o(shamt_o),
        .imm_o(imm_o)
    );

    logic [31:0] tests_passed;
    logic [31:0] tests_failed;

    // Test sequence
    initial begin

        tests_passed = 0;
        tests_failed = 0;
        $display("Starting Decode Module Testbench...");
        $display("======================================");
        // Initialize inputs
        insn_i = 32'b0;
        pc_i = 32'b0;
        #5;

        // Test case 1: R-type instruction (ADD x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_000_00101_0110011; // ADD x5, x6, x7
        pc_i = 32'h00000000;
        #5; // Wait for a clock cycle

                // Display outputs for verification
        $display("Test Case 1: R-type (ADD x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        $display("");

        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b000 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 1 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 1 Failed");
        end
        $display("");
        #10;

        // Test case 2: R-type instruction (SUB x5, x6, x7)
        insn_i = 32'b0100000_00111_00110_000_00101_0110011; // SUB x5, x6, x7
        pc_i = 32'h00000004;
        #10; // Wait for a clock cycle
        $display("Test Case 2: R-type (SUB x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);

        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b000 && 
            funct7_o == 7'b0100000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 2 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 2 Failed");
        end
        $display("");
        #10;

        // Test case 3: xor instruction (XOR x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_100_00101_0110011; // XOR x5, x6, x7
        pc_i = 32'h00000008;
        #10; // Wait for a clock cycle
        $display("Test Case 3: R-type (XOR x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 &&
            funct3_o == 3'b100 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 3 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 3 Failed");
        end
        $display("");
        #10;

        // Test case 4: R-type instruction (OR x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_110_00101_0110011; // OR x5, x6, x7
        pc_i = 32'h0000000C;
        #10; // Wait for a clock cycle

        $display("Test Case 4: R-type (OR x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b110 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 4 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 4 Failed");
        end

        // Test case 5: R-type instruction (AND x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_111_00101_0110011; // AND x5, x6, x7
        pc_i = 32'h00000010;
        #10; // Wait for a clock cycle
        $display("Test Case 5: R-type (AND x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b111 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 5 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 5 Failed");
        end
        $display("");
        #10;

        // Test case 6: R-type instruction (SLL x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_001_00101_0110011; // SLL x5, x6, x7
        pc_i = 32'h00000014;
        #10; // Wait for a clock cycle
        $display("Test Case 6: R-type (SLL x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, shamt: %d, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, shamt_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b001 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 6 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 6 Failed");
        end
        $display("");
        #10;
        
        // Test case 7: R-type instruction (SRL x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_101_00101_0110011; // SRL x5, x6, x7
        pc_i = 32'h00000018;
        #10; // Wait for a clock cycle
        $display("Test Case 7: R-type (SRL x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b101 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 7 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 7 Failed");
        end
        $display("");
        #10;

        // Test case 8: R-type instruction (SRA x5, x6, x7)
        insn_i = 32'b0100000_00111_00110_101_00101_0110011; // SRA x5, x6, x7
        pc_i = 32'h0000001C;
        #10; // Wait for a clock cycle
        $display("Test Case 8: R-type (SRA x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b101 && 
            funct7_o == 7'b0100000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 8 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 8 Failed");
        end
        $display("");
        #10;

        // Test case 9: R-type instruction (SLT x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_010_00101_0110011; // SLT x5, x6, x7
        pc_i = 32'h00000020;
        #10; // Wait for a clock cycle
        $display("Test Case 9: R-type (SLT x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b010 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 9 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 9 Failed");
        end
        $display("");
        #10;

        // Test case 10: R-type instruction (SLTU x5, x6, x7)
        insn_i = 32'b0000000_00111_00110_011_00101_0110011; // SLTU x5, x6, x7
        pc_i = 32'h00000024;
        #10; // Wait for a clock cycle
        $display("Test Case 10: R-type (SLTU x5, x6, x7)");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0110011 && 
            funct3_o == 3'b011 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd7 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 10 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 10 Failed");
        end
        $display("");
        #10;

        // Test case 11: I-type instruction (ADDI x5, x6, 10)
        insn_i = 32'b000000001010_00110_000_00101_0010011; // ADDI x5, x6, 10
        pc_i = 32'h00000028;
        #10; // Wait for a clock cycle
        $display("Test Case 11: I-type (ADDI x5, x6, 10)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b000 &&
            funct7_o == 7'b0000000 &&
            rd_o == 5'd5 && 
            rs1_o == 5'd6 &&
            rs2_o == 5'd0 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd10) begin
            tests_passed++;
            $display("Test Case 11 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 11 Failed");
        end
        $display("");
        #10;

        // Test case 12: I-type instruction (XORI x5, x6, 240)
        insn_i = 32'b000011110000_00110_100_00101_0010011; // XORI x5, x6, 240
        pc_i = 32'h0000002C;
        #10; // Wait for a clock cycle
        $display("Test Case 12: I-type (XORI x5, x6, 240)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b100 &&
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 &&
            rs2_o == 5'd0 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd240) begin
            tests_passed++;
            $display("Test Case 12 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 12 Failed");
        end
        $display("");
        #10;

        // Test case 13: I-type instruction (ORI x5, x6, 85)
        insn_i = 32'b000001010101_00110_110_00101_0010011; // ORI x5, x6, 85
        pc_i = 32'h00000030;
        #10; // Wait for a clock cycle
        $display("Test Case 13: I-type (ORI x5, x6, 85)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b110 && 
            funct7_o == 7'b0000000 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 &&
            rs2_o == 5'd0 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd85) begin
            tests_passed++;
            $display("Test Case 13 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 13 Failed");
        end
        $display("");
        #10;

        // Test case 14: I-type instruction (ANDI x5, x6, 255)
        insn_i = 32'b000011111111_00110_111_00101_0010011; // ANDI x5, x6, 255
        pc_i = 32'h00000034;
        #10; // Wait for a clock cycle
        $display("Test Case 14: I-type (ANDI x5, x6, 255)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b111 &&
            funct7_o == 7'b0000000 &&
            rd_o == 5'd5 && 
            rs1_o == 5'd6 &&
            rs2_o == 5'd0 &&
            shamt_o == 5'd0 &&
            imm_o == 32'd255) begin
            tests_passed++;
            $display("Test Case 14 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 14 Failed");
        end
        $display("");
        #10;

        // Test case 15: I-type instruction (SLLI x5, x6, 3)
        insn_i = 32'b0000000_00011_00110_001_00101_0010011; // SLLI x5, x6, 3
        pc_i = 32'h00000038;
        #10; // Wait for a clock cycle
        $display("Test Case 15: I-type (SLLI x5, x6, 3)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, funct7: %b, shamt: %d, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, funct7_o, shamt_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b001 && 
            funct7_o == 7'b0000000 &&
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd0 &&
            shamt_o == 5'd3 &&
            imm_o == 32'd3) begin
            tests_passed++;
            $display("Test Case 15 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 15 Failed");
        end
        $display("");
        #10;

        // Test case 16: I-type instruction (SRLI x5, x6, 3)
        insn_i = 32'b0000000_00011_00110_101_00101_0010011; // SRLI x5, x6, 3
        pc_i = 32'h0000003C;
        #10; // Wait for a clock cycle
        $display("Test Case 16: I-type (SRLI x5, x6, 3)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, funct7: %b, shamt: %d, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, funct7_o, shamt_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b101 && 
            funct7_o == 7'b0000000 &&
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd0 &&
            shamt_o == 5'd3 &&
            imm_o == 32'd3) begin
            tests_passed++;
            $display("Test Case 16 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 16 Failed");
        end
        $display("");
        #10;

        // Test case 17: I-type instruction (SRAI x5, x6, 3)
        insn_i = 32'b0100000_00011_00110_101_00101_0010011; // SRAI x5, x6, 3
        pc_i = 32'h00000040;
        #10; // Wait for a clock cycle
        $display("Test Case 17: I-type (SRAI x5, x6, 3)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, funct7: %b, shamt: %d, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, funct7_o, shamt_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b101 && 
            funct7_o == 7'b0100000 &&
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            rs2_o == 5'd0 &&
            shamt_o == 5'd3 &&
            imm_o == 32'd1027) begin  // imm[11:0] = 0100000_00011 = 1027
            tests_passed++;
            $display("Test Case 17 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 17 Failed");
        end
        $display("");
        #10;

        // Test case 18: I-type instruction (SLTI x5, x6, -5)
        insn_i = 32'b111111111011_00110_010_00101_0010011; // SLTI x5, x6, -5
        pc_i = 32'h00000044;
        #10; // Wait for a clock cycle
        $display("Test Case 18: I-type (SLTI x5, x6, -5)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, imm: %d (signed)", 
                 opcode_o, rd_o, rs1_o, funct3_o, $signed(imm_o));
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b010 &&
            funct7_o == 7'b0000000 &&
            rd_o == 5'd5 && 
            rs1_o == 5'd6 &&
            rs2_o == 5'd0 &&
            shamt_o == 5'd0 &&
            $signed(imm_o) == -5) begin
            tests_passed++;
            $display("Test Case 18 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 18 Failed");
        end
        $display("");
        #10;

        // Test case 19: I-type instruction (SLTIU x5, x6, 1000)
        insn_i = 32'b001111101000_00110_011_00101_0010011; // SLTIU x5, x6, 1000
        pc_i = 32'h00000048;
        #10; // Wait for a clock cycle
        $display("Test Case 19: I-type (SLTIU x5, x6, 1000)");
        $display("Opcode: %b, rd: %d, rs1: %d, funct3: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, funct3_o, imm_o);
        // Check outputs and increment test counters if correct or not
        if (opcode_o == 7'b0010011 && 
            funct3_o == 3'b011 && 
            rd_o == 5'd5 && 
            rs1_o == 5'd6 && 
            imm_o == 32'd1000) begin
            tests_passed++;
            $display("Test Case 19 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 19 Failed");
        end
        $display("");
        #10;

        // Display final summary
        $display("======================================");
        $display("Decode Module Test Summary:");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        $display("======================================");
        $finish;
    end
endmodule : decode_tb