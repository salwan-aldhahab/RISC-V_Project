`timescale 1ns/1ps
`include "constants.svh"

module control_tb;
    parameter int DWIDTH = 32;

    // DUT inputs
    logic [DWIDTH-1:0] insn_i;
    logic [6:0]        opcode_i;
    logic [6:0]        funct7_i;
    logic [2:0]        funct3_i;

    // DUT outputs
    logic pcsel_o;
    logic immsel_o;
    logic regwren_o;
    logic rs1sel_o;
    logic rs2sel_o;
    logic memren_o;
    logic memwren_o;
    logic [1:0] wbsel_o;
    logic [3:0] alusel_o;

    // Instantiate the control module
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

    // Book-keeping
    logic [31:0] tests_passed;
    logic [31:0] tests_failed;

    // Helper to drive inputs
    task drive(input [6:0] opc, input [2:0] f3, input [6:0] f7);
        opcode_i = opc;
        funct3_i = f3;
        funct7_i = f7;
        insn_i   = '0;   // not used by control; keep zero
        #1;
    endtask

    initial begin
        tests_passed = 0;
        tests_failed = 0;

        $display("Starting Control Module Testbench...");
        $display("======================================");

        // -------------------------------------------------------
        // Default / Unknown opcode
        // -------------------------------------------------------
        drive(7'b1111111, 3'b000, 7'b0000000);
        $display("Test Case 0: DEFAULT/UNKNOWN");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b memren=%0b memwren=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, memren_o, memwren_o, wbsel_o, alusel_o);
        if (pcsel_o==0 && immsel_o==0 && regwren_o==0 && rs1sel_o==0 && rs2sel_o==0 &&
            memren_o==0 && memwren_o==0 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 0 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 0 Failed\n");
        end
        #5;

        // -------------------------------------------------------
        // R-type: ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU
        // -------------------------------------------------------
        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_ADD);   // ADD
        $display("Test Case 1: R-type ADD");
        $display("pcsel=%0b immsel=%0b regwren=%0b rs1sel=%0b rs2sel=%0b wbsel=%02b alusel=%0h",
                 pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, wbsel_o, alusel_o);
        if (regwren_o==1 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==0 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 1 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 1 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_SUB);   // SUB
        $display("Test Case 2: R-type SUB");
        if (regwren_o==1 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==0 && wbsel_o==2'b00 && alusel_o==ALU_SUB) begin
            tests_passed++; $display("Test Case 2 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 2 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_AND, FUNCT7_AND);
        $display("Test Case 3: R-type AND");
        if (regwren_o==1 && alusel_o==ALU_AND && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 3 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 3 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_OR, FUNCT7_OR);
        $display("Test Case 4: R-type OR");
        if (regwren_o==1 && alusel_o==ALU_OR && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 4 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 4 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_XOR, FUNCT7_XOR);
        $display("Test Case 5: R-type XOR");
        if (regwren_o==1 && alusel_o==ALU_XOR && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 5 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 5 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SLL, FUNCT7_SLL);
        $display("Test Case 6: R-type SLL");
        if (regwren_o==1 && alusel_o==ALU_SLL && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 6 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 6 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SRL_SRA, FUNCT7_SRL);
        $display("Test Case 7: R-type SRL");
        if (regwren_o==1 && alusel_o==ALU_SRL && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 7 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 7 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SRL_SRA, FUNCT7_SRA);
        $display("Test Case 8: R-type SRA");
        if (regwren_o==1 && alusel_o==ALU_SRA && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 8 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 8 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SLT, FUNCT7_SLT);
        $display("Test Case 9: R-type SLT");
        if (regwren_o==1 && alusel_o==ALU_SLT && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 9 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 9 Failed\n");
        end
        #5;

        drive(OPCODE_RTYPE, FUNCT3_SLTU, FUNCT7_SLTU);
        $display("Test Case 10: R-type SLTU");
        if (regwren_o==1 && alusel_o==ALU_SLTU && wbsel_o==2'b00) begin
            tests_passed++; $display("Test Case 10 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 10 Failed\n");
        end
        #10;

        // -------------------------------------------------------
        // I-type (OP-IMM): ADDI/ANDI/ORI/XORI/SLLI/SRLI/SRAI/SLTI/SLTIU
        // -------------------------------------------------------
        drive(OPCODE_ITYPE, FUNCT3_ADD_SUB, 7'b0000000);   // ADDI
        $display("Test Case 11: I-type ADDI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 11 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 11 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_AND, 7'b0000000);       // ANDI
        $display("Test Case 12: I-type ANDI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_AND) begin
            tests_passed++; $display("Test Case 12 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 12 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_OR, 7'b0000000);        // ORI
        $display("Test Case 13: I-type ORI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_OR) begin
            tests_passed++; $display("Test Case 13 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 13 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_XOR, 7'b0000000);       // XORI
        $display("Test Case 14: I-type XORI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_XOR) begin
            tests_passed++; $display("Test Case 14 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 14 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SLL, 7'b0000000);       // SLLI
        $display("Test Case 15: I-type SLLI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLL) begin
            tests_passed++; $display("Test Case 15 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 15 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SRL_SRA, 7'b0000000);   // SRLI
        $display("Test Case 16: I-type SRLI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SRL) begin
            tests_passed++; $display("Test Case 16 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 16 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SRL_SRA, 7'b0100000);   // SRAI
        $display("Test Case 17: I-type SRAI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SRA) begin
            tests_passed++; $display("Test Case 17 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 17 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SLT, 7'b0000000);       // SLTI
        $display("Test Case 18: I-type SLTI");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLT) begin
            tests_passed++; $display("Test Case 18 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 18 Failed\n");
        end
        #5;

        drive(OPCODE_ITYPE, FUNCT3_SLTU, 7'b0000000);      // SLTIU
        $display("Test Case 19: I-type SLTIU");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && alusel_o==ALU_SLTU) begin
            tests_passed++; $display("Test Case 19 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 19 Failed\n");
        end
        #10;

        // -------------------------------------------------------
        // LOAD / STORE
        // -------------------------------------------------------
        drive(OPCODE_LOAD, FUNCT3_LW, 7'b0000000);
        $display("Test Case 20: LOAD (LW)");
        if (regwren_o==1 && rs2sel_o==1 && immsel_o==1 && memren_o==1 && wbsel_o==2'b01 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 20 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 20 Failed\n");
        end
        #5;

        drive(OPCODE_STORE, FUNCT3_SW, 7'b0000000);
        $display("Test Case 21: STORE (SW)");
        if (regwren_o==0 && rs2sel_o==1 && immsel_o==1 && memwren_o==1 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 21 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 21 Failed\n");
        end
        #10;

        // -------------------------------------------------------
        // BRANCH
        // -------------------------------------------------------
        drive(OPCODE_BRANCH, FUNCT3_BEQ, 7'b0000000);
        $display("Test Case 22: BRANCH (BEQ)");
        if (regwren_o==0 && rs1sel_o==0 && rs2sel_o==0 && immsel_o==1 && pcsel_o==0 && alusel_o==ALU_SUB) begin
            tests_passed++; $display("Test Case 22 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 22 Failed\n");
        end
        #10;

        // -------------------------------------------------------
        // JAL / JALR
        // -------------------------------------------------------
        drive(OPCODE_JAL, 3'b000, 7'b0000000);
        $display("Test Case 23: JAL");
        if (pcsel_o==1 && regwren_o==1 && immsel_o==1 && wbsel_o==2'b10 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 23 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 23 Failed\n");
        end
        #5;

        drive(OPCODE_JALR, 3'b000, 7'b0000000);
        $display("Test Case 24: JALR");
        if (pcsel_o==1 && regwren_o==1 && rs1sel_o==0 && rs2sel_o==1 && immsel_o==1 && wbsel_o==2'b10 && alusel_o==ALU_ADD) begin
            tests_passed++; $display("Test Case 24 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 24 Failed\n");
        end
        #10;

        // -------------------------------------------------------
        // U-type: LUI / AUIPC
        // -------------------------------------------------------
        drive(OPCODE_LUI, 3'b000, 7'b0000000);
        $display("Test Case 25: LUI");
        if (regwren_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_LUI) begin
            tests_passed++; $display("Test Case 25 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 25 Failed\n");
        end
        #5;

        drive(OPCODE_AUIPC, 3'b000, 7'b0000000);
        $display("Test Case 26: AUIPC");
        if (regwren_o==1 && immsel_o==1 && wbsel_o==2'b00 && alusel_o==ALU_AUIPC) begin
            tests_passed++; $display("Test Case 26 Passed\n");
        end else begin
            tests_failed++; $display("Test Case 26 Failed\n");
        end
        #10;

        // Final summary
        $display("======================================");
        $display("Control Module Test Summary:");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        $display("======================================");
        $finish;
    end
endmodule : control_tb
