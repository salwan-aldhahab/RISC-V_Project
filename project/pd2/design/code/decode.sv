/*
 * Module: decode
 *
 * Description: Decode stage - specific decoding for each RISC-V instruction type
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) insn_iruction ins_i
 * 4) program counter pc_i
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide insn_iruction output insn_o
 * 3) 5-bit wide destination register ID rd_o
 * 4) 5-bit wide source 1 register ID rs1_o
 * 5) 5-bit wide source 2 register ID rs2_o
 * 6) 7-bit wide funct7 funct7_o
 * 7) 3-bit wide funct3 funct3_o
 * 8) 32-bit wide immediate imm_o
 * 9) 5-bit wide shift amount shamt_o
 * 10) 7-bit width opcode_o
 */

`include "constants.svh"

module decode #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    // inputs
    input logic clk,
    input logic rst,
    input logic [DWIDTH - 1:0] insn_i,
    input logic [AWIDTH - 1:0] pc_i,

    // outputs
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o,
    output logic [6:0] opcode_o,
    output logic [4:0] rd_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output logic [2:0] funct3_o,
    output logic [4:0] shamt_o,  // shift amount
    output logic [DWIDTH-1:0] imm_o
);	

    /*
     * Instruction type identification and decoding
     * Based on RISC-V instruction formats: R, I, S, B, U, J
     */

    logic [DWIDTH-1:0] imm_internal;
    logic [6:0] opcode_internal;

    // Immediate generator
    igen #( .DWIDTH(DWIDTH) ) imm_gen (
        .opcode_i(insn_i[6:0]),
        .insn_i(insn_i),
        .imm_o(imm_internal)
    );

    // Extract opcode for instruction type determination
    assign opcode_internal = insn_i[6:0];

    always_comb begin
        // Default outputs
        pc_o = pc_i;
        insn_o = insn_i;
        opcode_o = opcode_internal;
        rd_o = 5'b0;
        rs1_o = 5'b0;
        rs2_o = 5'b0;
        funct7_o = 7'b0;
        funct3_o = 3'b0;
        shamt_o = 5'b0;
        imm_o = imm_internal;

        case (opcode_internal)
            // R-type instructions (ALU operations)
            OPCODE_RTYPE: begin  // 0110011
                rd_o = insn_i[11:7];
                funct3_o = insn_i[14:12];
                rs1_o = insn_i[19:15];
                rs2_o = insn_i[24:20];
                funct7_o = insn_i[31:25];
                shamt_o = 5'b0; // Not used in R-type
            end

            // I-type instructions (immediate ALU, loads, JALR)
            OPCODE_ITYPE, OPCODE_LOAD, OPCODE_JALR: begin  // 0010011, 0000011, 1100111
                rd_o = insn_i[11:7];
                funct3_o = insn_i[14:12];
                rs1_o = insn_i[19:15];
                rs2_o = 5'b0; // Not used in I-type
                if (opcode_internal == OPCODE_ITYPE && (funct3_o == FUNCT3_SLL || funct3_o == FUNCT3_SRL_SRA)) begin
                    // For shift instructions (SLLI, SRLI, SRAI), shamt is in rs2 field
                    funct7_o = insn_i[31:25];
                    shamt_o = insn_i[24:20];
                end
                funct7_o = 7'b0; // Default, unless it's a shift instruction
                shamt_o = 5'b0; // Default, unless it's a shift instruction
            end

            // S-type instructions (stores)
            OPCODE_STORE: begin  // 0100011
                rd_o = 5'b0; // Not used in S-type
                funct3_o = insn_i[14:12];
                rs1_o = insn_i[19:15]; // Base address
                rs2_o = insn_i[24:20]; // Source data
                funct7_o = 7'b0; // Not used in S-type
                shamt_o = 5'b0; // Not used in S-type
            end

            // B-type instructions (branches)
            OPCODE_BRANCH: begin  // 1100011
                rd_o = 5'b0; // Not used in B-type
                funct3_o = insn_i[14:12];
                rs1_o = insn_i[19:15];
                rs2_o = insn_i[24:20];
                funct7_o = 7'b0; // Not used in B-type
                shamt_o = 5'b0; // Not used in B-type
            end

            // U-type instructions (LUI, AUIPC)
            OPCODE_LUI, OPCODE_AUIPC: begin  // 0110111, 0010111
                rd_o = insn_i[11:7];
                funct3_o = 3'b0; // Not used in U-type
                rs1_o = 5'b0; // Not used in U-type (except AUIPC uses PC)
                rs2_o = 5'b0; // Not used in U-type
                funct7_o = 7'b0; // Not used in U-type
                shamt_o = 5'b0; // Not used in U-type
            end

            // J-type instructions (JAL)
            OPCODE_JAL: begin  // 1101111
                rd_o = insn_i[11:7];
                funct3_o = 3'b0; // Not used in J-type
                rs1_o = 5'b0; // Not used in J-type
                rs2_o = 5'b0; // Not used in J-type
                funct7_o = 7'b0; // Not used in J-type
                shamt_o = 5'b0; // Not used in J-type
            end

            default: begin
                // For unknown opcodes, extract all fields but don't assume their validity
                rd_o = insn_i[11:7];
                funct3_o = insn_i[14:12];
                rs1_o = insn_i[19:15];
                rs2_o = insn_i[24:20];
                funct7_o = insn_i[31:25];
                shamt_o = insn_i[24:20];
            end
        endcase
    end

endmodule : decode