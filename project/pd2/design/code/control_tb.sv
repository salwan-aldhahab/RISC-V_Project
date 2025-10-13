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

        // Test Case 0: What happens with unknown opcodes?
        drive(7'b1111111, 3'b000, 7'b0000000);
        #5;
        $display("Test Case 0: What happens with unknown opcodes?");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b memren=%0b memwren=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, memren_o, memwren_o, wbsel_o, alusel_o);
        
        if (pcsel_o==0 && immsel_o==0 && regwren_o==0 && rs1sel_o==0 && rs2sel_o==0 &&
            memren_o==0 && memwren_o==0 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 0 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 0 Failed");
        end
        $display("");
        #5;

        // Test Case 1: Simple addition (ADD rd, rs1, rs2)
        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_ADD);
        #5;
        $display("Test Case 1: Simple addition (ADD rd, rs1, rs2)");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, wbsel_o, alusel_o);
        
        if (regwren_o==1 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==0 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 1 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 1 Failed");
        end
        $display("");
        #5;

        // Test Case 2: Subtraction (SUB rd, rs1, rs2)
        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_SUB);
        #5;
        $display("Test Case 2: Subtraction (SUB rd, rs1, rs2)");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, wbsel_o, alusel_o);
        
        if (regwren_o==1 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==0 && wbsel_o==2'b00 && alusel_o==ALU_SUB) begin
            tests_passed++; 
            $display("Test Case 2 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 2 Failed");
        end
        $display("");
        #5;

        // Test Case 3: Bitwise AND
        drive(OPCODE_RTYPE, FUNCT3_AND, FUNCT7_AND);
        #5;
        $display("Test Case 3: Bitwise AND");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_AND && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 3 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 3 Failed");
        end
        $display("");
        #5;

        // Test Case 4: Bitwise OR
        drive(OPCODE_RTYPE, FUNCT3_OR, FUNCT7_OR);
        #5;
        $display("Test Case 4: Bitwise OR");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_OR && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 4 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 4 Failed");
        end
        $display("");
        #5;

        // Test Case 5: Bitwise XOR
        drive(OPCODE_RTYPE, FUNCT3_XOR, FUNCT7_XOR);
        #5;
        $display("Test Case 5: Bitwise XOR");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_XOR && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 5 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 5 Failed");
        end
        $display("");
        #5;

        // Test Case 6: Shift left logical
        drive(OPCODE_RTYPE, FUNCT3_SLL, FUNCT7_SLL);
        #5;
        $display("Test Case 6: Shift left logical");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_SLL && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 6 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 6 Failed");
        end
        $display("");
        #5;

        // Test Case 7: Shift right logical
        drive(OPCODE_RTYPE, FUNCT3_SRL_SRA, FUNCT7_SRL);
        #5;
        $display("Test Case 7: Shift right logical");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_SRL && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 7 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 7 Failed");
        end
        $display("");
        #5;

        // Test Case 8: Shift right arithmetic (preserves sign)
        drive(OPCODE_RTYPE, FUNCT3_SRL_SRA, FUNCT7_SRA);
        #5;
        $display("Test Case 8: Shift right arithmetic (preserves sign)");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_SRA && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 8 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 8 Failed");
        end
        $display("");
        #5;

        // Test Case 9: Set if less than (signed)
        drive(OPCODE_RTYPE, FUNCT3_SLT, FUNCT7_SLT);
        #5;
        $display("Test Case 9: Set if less than (signed)");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_SLT && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 9 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 9 Failed");
        end
        $display("");
        #5;

        // Test Case 10: Set if less than (unsigned)
        drive(OPCODE_RTYPE, FUNCT3_SLTU, FUNCT7_SLTU);
        #5;
        $display("Test Case 10: Set if less than (unsigned)");
        $display("regwren=%0b alusel=%0h wbsel=%02b", regwren_o, alusel_o, wbsel_o);
        
        if (regwren_o==1 && alusel_o==ALU_SLTU && wbsel_o==2'b00) begin
            tests_passed++; 
            $display("Test Case 10 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 10 Failed");
        end
        $display("");
        #10;

        // Test Case 11: Add immediate (ADDI rd, rs1, imm)
        drive(OPCODE_ITYPE, FUNCT3_ADD_SUB, 7'b0000000);
        #5;
        $display("Test Case 11: Add immediate (ADDI rd, rs1, imm)");
        $display("regwren=%0b rs2sel=%0b immsel=%0b wbsel=%02b alusel=%0h", regwren_o, rs2sel_o, immsel_o, wbsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 11 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 11 Failed");
        end
        $display("");
        #5;

        // Test Case 12: AND with immediate
        drive(OPCODE_ITYPE, FUNCT3_AND, 7'b0000000);
        #5;
        $display("Test Case 12: AND with immediate");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_AND) begin
            tests_passed++; 
            $display("Test Case 12 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 12 Failed");
        end
        $display("");
        #5;

        // Test Case 13: OR with immediate
        drive(OPCODE_ITYPE, FUNCT3_OR, 7'b0000000);
        #5;
        $display("Test Case 13: OR with immediate");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_OR) begin
            tests_passed++; 
            $display("Test Case 13 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 13 Failed");
        end
        $display("");
        #5;

        // Test Case 14: XOR with immediate
        drive(OPCODE_ITYPE, FUNCT3_XOR, 7'b0000000);
        #5;
        $display("Test Case 14: XOR with immediate");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_XOR) begin
            tests_passed++; 
            $display("Test Case 14 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 14 Failed");
        end
        $display("");
        #5;

        // Test Case 15: Shift left by immediate amount
        drive(OPCODE_ITYPE, FUNCT3_SLL, 7'b0000000);
        #5;
        $display("Test Case 15: Shift left by immediate amount");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLL) begin
            tests_passed++; 
            $display("Test Case 15 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 15 Failed");
        end
        $display("");
        #5;

        // Test Case 16: Shift right logical by immediate
        drive(OPCODE_ITYPE, FUNCT3_SRL_SRA, 7'b0000000);
        #5;
        $display("Test Case 16: Shift right logical by immediate");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SRL) begin
            tests_passed++; 
            $display("Test Case 16 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 16 Failed");
        end
        $display("");
        #5;

        // Test Case 17: Shift right arithmetic by immediate
        drive(OPCODE_ITYPE, FUNCT3_SRL_SRA, 7'b0100000);
        #5;
        $display("Test Case 17: Shift right arithmetic by immediate");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SRA) begin
            tests_passed++; 
            $display("Test Case 17 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 17 Failed");
        end
        $display("");
        #5;

        // Test Case 18: Compare with immediate (signed)
        drive(OPCODE_ITYPE, FUNCT3_SLT, 7'b0000000);
        #5;
        $display("Test Case 18: Compare with immediate (signed)");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLT) begin
            tests_passed++; 
            $display("Test Case 18 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 18 Failed");
        end
        $display("");
        #5;

        // Test Case 19: Compare with immediate (unsigned)
        drive(OPCODE_ITYPE, FUNCT3_SLTU, 7'b0000000);
        #5;
        $display("Test Case 19: Compare with immediate (unsigned)");
        $display("regwren=%0b rs2sel=%0b immsel=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLTU) begin
            tests_passed++; 
            $display("Test Case 19 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 19 Failed");
        end
        $display("");
        #10;

        // Test Case 20: Load word from memory
        drive(OPCODE_LOAD, FUNCT3_LW, 7'b0000000);
        #5;
        $display("Test Case 20: Load word from memory");
        $display("regwren=%0b rs2sel=%0b immsel=%0b memren=%0b wbsel=%02b alusel=%0h", regwren_o, rs2sel_o, immsel_o, memren_o, wbsel_o, alusel_o);
        
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && memren_o==1 && wbsel_o==2'b01 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 20 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 20 Failed");
        end
        $display("");
        #5;

        // Test Case 21: Store word to memory
        drive(OPCODE_STORE, FUNCT3_SW, 7'b0000000);
        #5;
        $display("Test Case 21: Store word to memory");
        $display("regwren=%0b rs2sel=%0b immsel=%0b memwren=%0b alusel=%0h", regwren_o, rs2sel_o, immsel_o, memwren_o, alusel_o);
        
        if (regwren_o==0 && rs2sel_o==1 && immsel_o==1 && memwren_o==1 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 21 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 21 Failed");
        end
        $display("");
        #10;

        // Test Case 22: Branch if equal
        drive(OPCODE_BRANCH, FUNCT3_BEQ, 7'b0000000);
        #5;
        $display("Test Case 22: Branch if equal");
        $display("regwren=%0b rs1sel=%0b rs2sel=%0b immsel=%0b pcsel=%0b alusel=%0h", regwren_o, rs1sel_o, rs2sel_o, immsel_o, pcsel_o, alusel_o);
        
        if (regwren_o==0 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==1 && pcsel_o==0 && alusel_o==ALU_SUB) begin
            tests_passed++; 
            $display("Test Case 22 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 22 Failed");
        end
        $display("");
        #10;

        // Test Case 23: Jump and link (save return address)
        drive(OPCODE_JAL, 3'b000, 7'b0000000);
        #5;
        $display("Test Case 23: Jump and link (save return address)");
        $display("pcsel=%0b regwren=%0b immsel=%0b wbsel=%02b alusel=%0h", pcsel_o, regwren_o, immsel_o, wbsel_o, alusel_o);
        
        if (pcsel_o==1 && regwren_o==1 && immsel_o==1 && wbsel_o==2'b10 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 23 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 23 Failed");
        end
        $display("");
        #5;

        // Test Case 24: Jump to register address and link
        drive(OPCODE_JALR, 3'b000, 7'b0000000);
        #5;
        $display("Test Case 24: Jump to register address and link");
        $display("pcsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b immsel=%0b wbsel=%02b alusel=%0h", pcsel_o, regwren_o, rs1sel_o, rs2sel_o, immsel_o, wbsel_o, alusel_o);
        
        if (pcsel_o==1 && regwren_o==1 && rs1sel_o==0 && rs2sel_o==1 && immsel_o==1 && wbsel_o==2'b10 && alusel_o==ALU_ADD) begin
            tests_passed++; 
            $display("Test Case 24 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 24 Failed");
        end
        $display("");
        #10;

        // Test Case 25: Load upper immediate (set high 20 bits)
        drive(OPCODE_LUI, 3'b000, 7'b0000000);
        #5;
        $display("Test Case 25: Load upper immediate (set high 20 bits)");
        $display("regwren=%0b immsel=%0b wbsel=%02b alusel=%0h", regwren_o, immsel_o, wbsel_o, alusel_o);
        
        if (regwren_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_LUI) begin
            tests_passed++; 
            $display("Test Case 25 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 25 Failed");
        end
        $display("");
        #5;

        // Test Case 26: Add upper immediate to PC
        drive(OPCODE_AUIPC, 3'b000, 7'b0000000);
        #5;
        $display("Test Case 26: Add upper immediate to PC");
        $display("regwren=%0b immsel=%0b wbsel=%02b alusel=%0h", regwren_o, immsel_o, wbsel_o, alusel_o);
        
        if (regwren_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_AUIPC) begin
            tests_passed++; 
            $display("Test Case 26 Passed");
        end else begin
            tests_failed++; 
            $display("Test Case 26 Failed");
        end
        $display("");
        #10;

        // Display final summary
        $display("======================================");
        $display("Control Module Test Summary:");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        $display("======================================");
        $finish;
    end
endmodule : control_tb
