/*
 * Module: alu
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 7-bit opcode opcode_i
 * 5) 3-bit funct3 funct3_i
 * 6) 7-bit funct7 funct7_i
 *
 * Outputs:
 * 1) 32-bit result of ALU res_o
 * 2) 1-bit branch taken signal brtaken_o
 */

`include "constants.svh"

module alu #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input logic [AWIDTH-1:0] pc_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    output logic [DWIDTH-1:0] res_o,
    output logic brtaken_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    // Instantiate branch control module
    logic breq_o;
    logic brlt_o;
    branch_control br_ctrl (
        .opcode_i (opcode_i),
        .funct3_i (funct3_i),
        .rs1_i   (rs1_i),
        .rs2_i   (rs2_i),
        .breq_o   (breq_o),
        .brlt_o   (brlt_o)
    );

    // ALU operation block based on opcode
    always_comb begin
        // Default output
        res_o = ZERO;
        brtaken_o = 1'b0;

        case (opcode_i)
            OPCODE_R_TYPE: begin // R-type instructions
                case (funct3_i)
                    FUNCT3_ADD_SUB: begin // ADD/SUB
                        if (funct7_i == FUNCT7_SUB)
                            res_o = rs1_i - rs2_i; // SUB
                        else
                            res_o = rs1_i + rs2_i; // ADD
                    end
                    FUNCT3_SLL: res_o = rs1_i << rs2_i[4:0]; // SLL
                    FUNCT3_SLT: res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : ZERO; // SLT
                    FUNCT3_SLTU: res_o = (rs1_i < rs2_i) ? 32'd1 : ZERO; // SLTU
                    FUNCT3_XOR: res_o = rs1_i ^ rs2_i; // XOR
                    FUNCT3_SRL_SRA: begin // SRL/SRA
                        if (funct7_i == FUNCT7_SRA)
                            res_o = $signed(rs1_i) >>> rs2_i[4:0]; // SRA
                        else
                            res_o = rs1_i >> rs2_i[4:0]; // SRL
                    end
                    FUNCT3_OR: res_o = rs1_i | rs2_i; // OR
                    FUNCT3_AND: res_o = rs1_i & rs2_i; // AND
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_I_TYPE: begin // I-type arithmetic instructions
                case (funct3_i)
                    FUNCT3_ADD_SUB: res_o = rs1_i + rs2_i; // ADDI
                    FUNCT3_SLL: res_o = rs1_i << rs2_i[4:0]; // SLLI
                    FUNCT3_SLT: res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : ZERO; // SLTI
                    FUNCT3_SLTU: res_o = (rs1_i < rs2_i) ? 32'd1 : ZERO; // SLTIU
                    FUNCT3_XOR: res_o = rs1_i ^ rs2_i; // XORI
                    FUNCT3_SRL_SRA: begin // SRLI/SRAI
                        if (rs2_i[10] == 1'b1) // Check immediate bit 10 for SRAI
                            res_o = $signed(rs1_i) >>> rs2_i[4:0]; // SRAI
                        else
                            res_o = rs1_i >> rs2_i[4:0]; // SRLI
                    end
                    FUNCT3_OR: res_o = rs1_i | rs2_i; // ORI
                    FUNCT3_AND: res_o = rs1_i & rs2_i; // ANDI
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_LOAD: begin // Load instructions
                case (funct3_i)
                    FUNCT3_LB, FUNCT3_LBU, FUNCT3_LH, FUNCT3_LHU, FUNCT3_LW: begin
                        res_o = rs1_i + rs2_i; // Calculate memory address
                    end
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_STORE: begin // Store instructions
                case (funct3_i)
                    FUNCT3_SB, FUNCT3_SH, FUNCT3_SW: begin
                        res_o = rs1_i + rs2_i; // Calculate memory address
                    end
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_BRANCH: begin // Branch instructions
                res_o = pc_i + rs2_i; // Branch target address
                case (funct3_i)
                    FUNCT3_BEQ: brtaken_o = breq_o; // BEQ
                    FUNCT3_BNE: brtaken_o = ~breq_o; // BNE
                    FUNCT3_BLT: brtaken_o = brlt_o; // BLT
                    FUNCT3_BGE: brtaken_o = ~brlt_o | breq_o; // BGE
                    FUNCT3_BLTU: brtaken_o = brlt_o; // BLTU
                    FUNCT3_BGEU: brtaken_o = ~brlt_o | breq_o; // BGEU
                    default: brtaken_o = 1'b0;
                endcase
            end

            OPCODE_JAL: begin // JAL
                res_o = pc_i + 32'd4; // Return address
                brtaken_o = 1'b1;
            end

            OPCODE_JALR: begin // JALR
                res_o = pc_i + 32'd4; // Return address
                brtaken_o = 1'b1;
            end

            OPCODE_LUI: begin // LUI
                res_o = rs2_i; // Load upper immediate (rs2_i contains imm[31:12] << 12)
            end

            OPCODE_AUIPC: begin // AUIPC
                res_o = pc_i + rs2_i; // Add upper immediate to PC
            end

            default: begin
                res_o = ZERO;
                brtaken_o = 1'b0;
            end
        endcase
    end

endmodule : alu