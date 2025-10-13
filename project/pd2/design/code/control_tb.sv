`timescale 1ns / 1ps
`include "constants.svh"

/*
 * Testbench: control_tb
 * --------------------------------------------
 * Purpose:
 *   Verify that the control unit correctly sets
 *   control signals based on the opcode, funct3,
 *   and funct7 of RISC-V instructions.
 *
 * Notes:
 *   - Self-checking testbench with clear output.
 *   - Each test prints "PASS" or "FAIL".
 *   - Make sure constants.svh is included.
 */

module control_tb;

    // -------------------------
    // DUT I/O Declarations
    // -------------------------
    logic [31:0] insn_i;
    logic [6:0]  opcode_i;
    logic [6:0]  funct7_i;
    logic [2:0]  funct3_i;

    logic        pcsel_o;
    logic        immsel_o;
    logic        regwren_o;
    logic        rs1sel_o;
    logic        rs2sel_o;
    logic        memren_o;
    logic        memwren_o;
    logic [1:0]  wbsel_o;
    logic [3:0]  alusel_o;

    // -------------------------
    // Instantiate the DUT
    // -------------------------
    control dut (
        .insn_i(insn_i),
        .opcode_i(opcode_i),
        .funct7_i(funct7_i),
        .funct3_i(funct3_i),
        .pcsel_o(pcsel_o),
        .immsel_o(immsel_o),
        .regwren_o(regwren_o),
        .rs1sel_o(rs1sel_o),
        .rs2sel_o(rs2sel_o),
        .memren_o(memren_o),
        .memwren_o(memwren_o),
        .wbsel_o(wbsel_o),
        .alusel_o(alusel_o)
    );

    // -------------------------
    // Testbench Counters
    // -------------------------
    int tests_passed = 0;
    int tests_failed = 0;

    // Shortcuts for write-back select encodings
    localparam WB_ALU = 2'b00;  // ALU result
    localparam WB_MEM = 2'b01;  // Memory load
    localparam WB_PC4 = 2'b10;  // PC + 4

    // -------------------------
    // Helper Task: Compare and Report
    // -------------------------
    task automatic check(
        string test_name,
        logic exp_pcsel,
        logic exp_immsel,
        logic exp_regwren,
        logic exp_rs1sel,
        logic exp_rs2sel,
        logic exp_memren,
        logic exp_memwren,
        logic [1:0] exp_wbsel,
        logic [3:0] exp_alusel
    );
        #1; // Wait a tiny bit for combinational logic to settle
        if (pcsel_o   === exp_pcsel   &&
            immsel_o  === exp_immsel  &&
            regwren_o === exp_regwren &&
            rs1sel_o  === exp_rs1sel  &&
            rs2sel_o  === exp_rs2sel  &&
            memren_o  === exp_memren  &&
            memwren_o === exp_memwren &&
            wbsel_o   === exp_wbsel   &&
            alusel_o  === exp_alusel) begin
            $display("[PASS] %s", test_name);
            tests_passed++;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("  Got -> pcsel=%b immsel=%b regwren=%b rs1sel=%b rs2sel=%b memren=%b memwren=%b wbsel=%b alusel=%h",
                     pcsel_o, immsel_o, regwren_o, rs1sel_o, rs2sel_o, memren_o, memwren_o, wbsel_o, alusel_o);
            $display("  Exp -> pcsel=%b immsel=%b regwren=%b rs1sel=%b rs2sel=%b memren=%b memwren=%b wbsel=%b alusel=%h\n",
                     exp_pcsel, exp_immsel, exp_regwren, exp_rs1sel, exp_rs2sel, exp_memren, exp_memwren, exp_wbsel, exp_alusel);
            tests_failed++;
        end
    endtask

    // -------------------------
    // Drive Opcode/Funct Values
    // -------------------------
    task automatic drive(input [6:0] opc, input [2:0] f3, input [6:0] f7);
        opcode_i = opc;
        funct3_i = f3;
        funct7_i = f7;
        insn_i   = 32'h0;
        #1;
    endtask

    // -------------------------
    // Main Test Sequence
    // -------------------------
    initial begin
        $display("\n==============================");
        $display("  CONTROL UNIT TESTBENCH RUN");
        $display("==============================\n");

        // Default / Unknown opcode
        drive(7'b1111111, 3'b000, 7'b0000000);
        check("Default (unknown opcode)",
              0,0,0,0,0,0,0,WB_ALU,ALU_ADD);

        // ---------- R-Type ----------
        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_ADD);
        check("R-Type ADD", 0,0,1,0,0,0,0,WB_ALU,ALU_ADD);

        drive(OPCODE_RTYPE, FUNCT3_ADD_SUB, FUNCT7_SUB);
        check("R-Type SUB", 0,0,1,0,0,0,0,WB_ALU,ALU_SUB);

        drive(OPCODE_RTYPE, FUNCT3_AND, FUNCT7_AND);
        check("R-Type AND", 0,0,1,0,0,0,0,WB_ALU,ALU_AND);

        drive(OPCODE_RTYPE, FUNCT3_OR, FUNCT7_OR);
        check("R-Type OR", 0,0,1,0,0,0,0,WB_ALU,ALU_OR);

        drive(OPCODE_RTYPE, FUNCT3_XOR, FUNCT7_XOR);
        check("R-Type XOR", 0,0,1,0,0,0,0,WB_ALU,ALU_XOR);

        // ---------- I-Type ----------
        drive(OPCODE_ITYPE, FUNCT3_ADD_SUB, 7'b0000000);
        check("I-Type ADDI", 0,1,1,0,1,0,0,WB_ALU,ALU_ADD);

        drive(OPCODE_ITYPE, FUNCT3_AND, 7'b0000000);
        check("I-Type ANDI", 0,1,1,0,1,0,0,WB_ALU,ALU_AND);

        drive(OPCODE_ITYPE, FUNCT3_OR, 7'b0000000);
        check("I-Type ORI",  0,1,1,0,1,0,0,WB_ALU,ALU_OR);

        drive(OPCODE_ITYPE, FUNCT3_XOR, 7'b0000000);
        check("I-Type XORI", 0,1,1,0,1,0,0,WB_ALU,ALU_XOR);

        // ---------- Load / Store ----------
        drive(OPCODE_LOAD, FUNCT3_LW, 7'b0000000);
        check("Load (LW)", 0,1,1,0,1,1,0,WB_MEM,ALU_ADD);

        drive(OPCODE_STORE, FUNCT3_SW, 7'b0000000);
        check("Store (SW)", 0,1,0,0,1,0,1,WB_ALU,ALU_ADD);

        // ---------- Branch ----------
        drive(OPCODE_BRANCH, FUNCT3_BEQ, 7'b0000000);
        check("Branch (BEQ)", 0,1,0,0,0,0,0,WB_ALU,ALU_SUB);

        // ---------- JAL / JALR ----------
        drive(OPCODE_JAL, 3'b000, 7'b0000000);
        check("JAL", 1,1,1,1,1,0,0,WB_PC4,ALU_ADD);

        drive(OPCODE_JALR, 3'b000, 7'b0000000);
        check("JALR", 1,1,1,0,1,0,0,WB_PC4,ALU_ADD);

        // ---------- LUI / AUIPC ----------
        drive(OPCODE_LUI, 3'b000, 7'b0000000);
        check("LUI", 0,1,1,1,1,0,0,WB_ALU,ALU_LUI);

        drive(OPCODE_AUIPC, 3'b000, 7'b0000000);
        check("AUIPC", 0,1,1,1,1,0,0,WB_ALU,ALU_AUIPC);

        // -------------------------
        // Summary
        // -------------------------
        $display("\n==============================");
        $display("  TESTBENCH SUMMARY");
        $display("==============================");
        $display("  Tests Passed : %0d", tests_passed);
        $display("  Tests Failed : %0d", tests_failed);
        $display("==============================\n");

        if (tests_failed == 0)
            $display("✅ All tests passed!");
        else
            $display("❌ Some tests failed. Check logs above.");

        $finish;
    end
endmodule
