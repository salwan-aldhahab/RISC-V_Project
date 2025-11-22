/*
 * Module: decode
 *
 * Description: Decode stage
 *
 * -------- REPLACE THIS FILE WITH THE DECODE MODULE DEVELOPED IN PD2 -----------
 */

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
        // Initialize all outputs with safe defaults
        pc_o = pc_i;
        insn_o = insn_i;
        opcode_o = opcode_internal;
        
        rd_o = insn_i[11:7];
        rs1_o = insn_i[19:15];
        rs2_o = insn_i[24:20];
        funct7_o = insn_i[31:25];
        funct3_o = insn_i[14:12];
        shamt_o = insn_i[24:20]; // Default shift amount from rs2 field
        imm_o = imm_internal;

        // Decode instruction based on opcode (determines instruction format)
        case (opcode_internal)
            
            // R-Type: Register-Register operations (ADD, SUB, AND, OR, etc.)
            // Format: funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
            OPCODE_RTYPE: begin
                rd_o = insn_i[11:7];     // Destination register
                funct3_o = insn_i[14:12]; // Function code (operation type)
                rs1_o = insn_i[19:15];    // First source register
                rs2_o = insn_i[24:20];    // Second source register
                funct7_o = insn_i[31:25]; // Extended function code
                // Note: shamt_o remains 0 as R-type doesn't use shift amounts
            end

            // I-Type: Immediate operations, Loads, and JALR
            // Format: imm[31:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
            OPCODE_ITYPE, OPCODE_LOAD, OPCODE_JALR: begin
                rd_o = insn_i[11:7];     // Destination register
                funct3_o = insn_i[14:12]; // Function code (determines operation/load size)
                rs1_o = insn_i[19:15];    // Source register (base for loads, operand for ALU)
                // rs2_o remains 0 (I-type uses immediate, not second register)
                
                rs2_o = 5'd0; // I-type instructions do not use rs2

                // Special handling for shift instructions within I-type
                if (opcode_internal == OPCODE_ITYPE && 
                   (funct3_o == FUNCT3_SLL || funct3_o == FUNCT3_SRL_SRA)) begin
                    // Shift instructions encode shift amount in immediate field
                    funct7_o = insn_i[31:25]; // Distinguishes logical vs arithmetic right shift
                    shamt_o = insn_i[24:20];  // 5-bit shift amount (0-31)
                end
                // For non-shift I-type instructions, funct7 and shamt remain 0
            end

            // S-Type: Store instructions
            // Format: imm[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[11:7] | opcode[6:0]
            OPCODE_STORE: begin
                // rd_o remains 0 (stores don't write to registers)
                funct3_o = insn_i[14:12]; // Store size (byte, half-word, word)
                rs1_o = insn_i[19:15];    // Base address register
                rs2_o = insn_i[24:20];    // Source data register
                // funct7_o and shamt_o remain 0 (not used in S-type)
            end

            // B-Type: Branch instructions
            // Format: imm[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[11:7] | opcode[6:0]
            OPCODE_BRANCH: begin
                // rd_o remains 0 (branches don't write to registers)
                funct3_o = insn_i[14:12]; // Branch condition (equal, less than, etc.)
                rs1_o = insn_i[19:15];    // First comparison register
                rs2_o = insn_i[24:20];    // Second comparison register
                // funct7_o and shamt_o remain 0 (not used in B-type)
            end

            // U-Type: Upper immediate instructions (LUI, AUIPC)
            // Format: imm[31:12] | rd[11:7] | opcode[6:0]
            OPCODE_LUI, OPCODE_AUIPC: begin
                rd_o = insn_i[11:7];      // Destination register
                // All other register fields remain 0 (U-type only uses immediate and rd)
                // Note: AUIPC implicitly uses PC, but no explicit rs1 encoding
            end

            // J-Type: Jump and link (JAL)
            // Format: imm[31:12] | rd[11:7] | opcode[6:0]
            OPCODE_JAL: begin
                rd_o = insn_i[11:7];      // Destination register (stores return address)
                // All other register and function fields remain 0
                // Jump target calculated from PC + immediate (handled by imm_o)
            end

            // Handle unrecognized opcodes gracefully
            default: begin
                // Extract all possible fields for debugging/analysis purposes
                // This helps identify malformed or unsupported instructions
                rd_o = insn_i[11:7];      // Potential destination register
                funct3_o = insn_i[14:12]; // Potential function code
                rs1_o = insn_i[19:15];    // Potential first source register
                rs2_o = insn_i[24:20];    // Potential second source register
                funct7_o = insn_i[31:25]; // Potential extended function code
                shamt_o = insn_i[24:20];  // Potential shift amount (same as rs2)
                
                // Note: These extractions may not be meaningful for unknown instructions
                // but provide maximum information for error analysis
            end
        endcase
    end

endmodule : decode