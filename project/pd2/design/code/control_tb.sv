`timescale 1ns/1ps
`include "constants.svh"

module control_tb;
    parameter int DWIDTH = 32;

    // Inputs to the control unit we're testing
    logic [DWIDTH-1:0] insn_i;
    logic [6:0]        opcode_i;
    logic [6:0]        funct7_i;
    logic [2:0]        funct3_i;

    // Control signals that come out of our unit
    logic pcsel_o;      // Decides if we use ALU result or PC+4 for next PC
    logic immsel_o;     // Choose between register or immediate value
    logic regwren_o;    // Enable writing to the register file
    logic rs1sel_o;     // Select source 1 (register vs PC)
    logic rs2sel_o;     // Select source 2 (register vs immediate)
    logic memren_o;     // Enable memory reads
    logic memwren_o;    // Enable memory writes
    logic [1:0] wbsel_o; // What to write back: ALU result, memory, or PC+4
    logic [3:0] alusel_o; // Which ALU operation to perform

    // Create an instance of our control module to test
    control #( .DWIDTH(DWIDTH) ) dut (
        .insn_i   (insn_i),
        .opcode_i (opcode_i),
        .funct7_i (funct7_i),
        .funct3_i (funct3_i),
        .pcsel_o  (pcsel_o),
        .immsel_o (immsel_o),
        .regwren_o(regwren_o),
        .rs1sel_o (rs1sel_o),
        .rs2sel_o (rs2sel_o),
        .memren_o (memren_o),
        .memwren_o(memwren_o),
        .wbsel_o  (wbsel_o),
        .alusel_o (alusel_o)
    );

    // Keep track of how we're doing
    logic [31:0] tests_passed;
    logic [31:0] tests_failed;

    // Simple helper to set up test inputs and wait a bit
    task drive(input [6:0] opc, input [2:0] f3, input [6:0] f7);
        opcode_i = opc;
        funct3_i = f3;
        funct7_i = f7;
        insn_i   = '0;   // Our control unit doesn't need the full instruction
        #1;              // Give the logic time to settle
    endtask

    initial begin
        tests_passed = 0;
        tests_failed = 0;

        $display("Starting Control Module Testbench...");
        $display("======================================");

        // Let's see what happens with garbage input
        drive(7'b1111111, 3'b000, 7'b0000000);
        $display("Test Case 0: What happens with unknown opcodes?");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b memren=%0b memwren=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, memren_o, memwren_o, wbsel_o, alusel_o);
        if (pcsel_o==0 && immsel_o==0 && regwren_o==0 && rs1sel_o==0 && rs2sel_o==0 &&
            memren_o==0 && memwren_o==0 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ Unknown opcodes default to safe values\n");
        end else begin
            tests_failed++; $display("✗ Unexpected behavior for unknown opcodes\n");
        end
        #5;

        // Test all the basic arithmetic operations (register-to-register)
        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_ADD);
        $display("Test Case 1: Simple addition (ADD rd, rs1, rs2)");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, wbsel_o, alusel_o);
        if (regwren_o==1 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==0 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ ADD configured correctly\n");
        end else begin
            tests_failed++; $display("✗ ADD not working as expected\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_SUB);
        $display("Test Case 2: Subtraction (SUB rd, rs1, rs2)");
        if (regwren_o==1 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==0 && wbsel_o==2'b00 && alusel_o==ALU_SUB) begin
            tests_passed++; $display("✓ SUB configured correctly\n");
        end else begin
            tests_failed++; $display("✗ SUB not working as expected\n");
        end
        #5;

        // Test the bitwise operations
        drive(OPCODE_RTYPE, FUNCT3_AND, FUNCT7_AND);
        $display("Test Case 3: Bitwise AND");
        if (regwren_o==1 && alusel_o==ALU_AND && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ AND working fine\n");
        end else begin
            tests_failed++; $display("✗ AND has issues\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_OR, FUNCT7_OR);
        $display("Test Case 4: Bitwise OR");
        if (regwren_o==1 && alusel_o==ALU_OR && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ OR working fine\n");
        end else begin
            tests_failed++; $display("✗ OR has issues\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_XOR, FUNCT7_XOR);
        $display("Test Case 5: Bitwise XOR");
        if (regwren_o==1 && alusel_o==ALU_XOR && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ XOR working fine\n");
        end else begin
            tests_failed++; $display("✗ XOR has issues\n");
        end
        #5;

        // Test the shift operations
        drive(OPCODE_RTYPE, FUNCT3_SLL, FUNCT7_SLL);
        $display("Test Case 6: Shift left logical");
        if (regwren_o==1 && alusel_o==ALU_SLL && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ Left shift working\n");
        end else begin
            tests_failed++; $display("✗ Left shift problems\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SRL_SRA, FUNCT7_SRL);
        $display("Test Case 7: Shift right logical");
        if (regwren_o==1 && alusel_o==ALU_SRL && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ Right logical shift working\n");
        end else begin
            tests_failed++; $display("✗ Right logical shift problems\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SRL_SRA, FUNCT7_SRA);
        $display("Test Case 8: Shift right arithmetic (preserves sign)");
        if (regwren_o==1 && alusel_o==ALU_SRA && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ Arithmetic right shift working\n");
        end else begin
            tests_failed++; $display("✗ Arithmetic right shift problems\n");
        end
        #5;

        // Test comparison operations
        drive(OPCODE_RTYPE, FUNCT3_SLT, FUNCT7_SLT);
        $display("Test Case 9: Set if less than (signed)");
        if (regwren_o==1 && alusel_o==ALU_SLT && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ Signed comparison working\n");
        end else begin
            tests_failed++; $display("✗ Signed comparison issues\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SLTU, FUNCT7_SLTU);
        $display("Test Case 10: Set if less than (unsigned)");
        if (regwren_o==1 && alusel_o==ALU_SLTU && wbsel_o==2'b00) begin
            tests_passed++; $display("✓ Unsigned comparison working\n");
        end else begin
            tests_failed++; $display("✗ Unsigned comparison issues\n");
        end
        #10;

        // Now test immediate operations (same operations but with constants)
        drive(OPCODE_ITYPE, FUNCT3_ADD_SUB, 7'b0000000);
        $display("Test Case 11: Add immediate (ADDI rd, rs1, imm)");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ Add immediate working (using immediate instead of rs2)\n");
        end else begin
            tests_failed++; $display("✗ Add immediate not configured right\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_AND, 7'b0000000);
        $display("Test Case 12: AND with immediate");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_AND) begin
            tests_passed++; $display("✓ AND immediate working\n");
        end else begin
            tests_failed++; $display("✗ AND immediate problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_OR, 7'b0000000);
        $display("Test Case 13: OR with immediate");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_OR) begin
            tests_passed++; $display("✓ OR immediate working\n");
        end else begin
            tests_failed++; $display("✗ OR immediate problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_XOR, 7'b0000000);
        $display("Test Case 14: XOR with immediate");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_XOR) begin
            tests_passed++; $display("✓ XOR immediate working\n");
        end else begin
            tests_failed++; $display("✗ XOR immediate problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SLL, 7'b0000000);
        $display("Test Case 15: Shift left by immediate amount");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLL) begin
            tests_passed++; $display("✓ Shift left immediate working\n");
        end else begin
            tests_failed++; $display("✗ Shift left immediate problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SRL_SRA, 7'b0000000);
        $display("Test Case 16: Shift right logical by immediate");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SRL) begin
            tests_passed++; $display("✓ Shift right logical immediate working\n");
        end else begin
            tests_failed++; $display("✗ Shift right logical immediate problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SRL_SRA, 7'b0100000);
        $display("Test Case 17: Shift right arithmetic by immediate");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SRA) begin
            tests_passed++; $display("✓ Shift right arithmetic immediate working\n");
        end else begin
            tests_failed++; $display("✗ Shift right arithmetic immediate problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SLT, 7'b0000000);
        $display("Test Case 18: Compare with immediate (signed)");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLT) begin
            tests_passed++; $display("✓ Signed immediate comparison working\n");
        end else begin
            tests_failed++; $display("✗ Signed immediate comparison problems\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SLTU, 7'b0000000);
        $display("Test Case 19: Compare with immediate (unsigned)");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLTU) begin
            tests_passed++; $display("✓ Unsigned immediate comparison working\n");
        end else begin
            tests_failed++; $display("✗ Unsigned immediate comparison problems\n");
        end
        #10;

        // Test memory operations
        drive(OPCODE_LOAD, FUNCT3_LW, 7'b0000000);
        $display("Test Case 20: Load word from memory");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && memren_o==1 && wbsel_o==2'b01 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ Load instruction setup correctly (address = rs1 + offset)\n");
        end else begin
            tests_failed++; $display("✗ Load instruction not configured right\n");
        end
        #5;

        drive(OPCODE_STORE, FUNCT3_SW, 7'b0000000);
        $display("Test Case 21: Store word to memory");
        if (regwren_o==0 && rs2sel_o==1 && immsel_o==1 && memwren_o==1 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ Store instruction setup correctly (don't write to register)\n");
        end else begin
            tests_failed++; $display("✗ Store instruction not configured right\n");
        end
        #10;

        // Test branch operations
        drive(OPCODE_BRANCH, FUNCT3_BEQ, 7'b0000000);
        $display("Test Case 22: Branch if equal");
        if (regwren_o==0 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==1 && pcsel_o==0 && alusel_o==ALU_SUB) begin
            tests_passed++; $display("✓ Branch setup correctly (compare rs1 and rs2)\n");
        end else begin
            tests_failed++; $display("✗ Branch not configured right\n");
        end
        #10;

        // Test jump operations
        drive(OPCODE_JAL, 3'b000, 7'b0000000);
        $display("Test Case 23: Jump and link (save return address)");
        if (pcsel_o==1 && regwren_o==1 && immsel_o==1 && wbsel_o==2'b10 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ JAL working (jump to PC + offset, save PC+4)\n");
        end else begin
            tests_failed++; $display("✗ JAL not working right\n");
        end
        #5;

        drive(OPCODE_JALR, 3'b000, 7'b0000000);
        $display("Test Case 24: Jump to register address and link");
        if (pcsel_o==1 && regwren_o==1 && rs1sel_o==0 && rs2sel_o==1 && immsel_o==1 && wbsel_o==2'b10 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("✓ JALR working (jump to rs1 + offset, save PC+4)\n");
        end else begin
            tests_failed++; $display("✗ JALR not working right\n");
        end
        #10;

        // Test upper immediate operations
        drive(OPCODE_LUI, 3'b000, 7'b0000000);
        $display("Test Case 25: Load upper immediate (set high 20 bits)");
        if (regwren_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_LUI) begin
            tests_passed++; $display("✓ LUI working (load 20-bit constant to upper bits)\n");
        end else begin
            tests_failed++; $display("✗ LUI not working\n");
        end
        #5;

        drive(OPCODE_AUIPC, 3'b000, 7'b0000000);
        $display("Test Case 26: Add upper immediate to PC");
        if (regwren_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_AUIPC) begin
            tests_passed++; $display("✓ AUIPC working (PC + 20-bit constant)\n");
        end else begin
            tests_failed++; $display("✗ AUIPC not working\n");
        end
        #10;

        // Show the final results
        $display("======================================");
        $display("Control Module Test Summary:");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        if (tests_failed == 0) begin
            $display("🎉 All tests passed! Your control unit looks good!");
        end else begin
            $display("⚠️  Some tests failed. Check the logic above.");
        end
        $display("======================================");
        $finish;
    end
endmodule : control_tb
