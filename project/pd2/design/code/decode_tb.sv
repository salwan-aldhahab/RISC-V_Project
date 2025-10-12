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
            shamt_o == 5'd7 &&
            imm_o == 32'd0) begin
            tests_passed++;
            $display("Test Case 6 Passed");
        end else begin
            tests_failed++;
            $display("Test Case 6 Failed");
        end

        // Display final summary
        $display("======================================");
        $display("Decode Module Test Summary:");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        $display("======================================");
        $finish;
    end
endmodule : decode_tb