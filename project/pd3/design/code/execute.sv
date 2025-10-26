/*
 * Module: alu
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 3-bit funct3 funct3_i
 * 5) 7-bit funct7 funct7_i
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
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    output logic [DWIDTH-1:0] res_o,
    output logic brtaken_o
);

    // Instantiate branch control module
    logic breq_o;
    logic brlt_o;
    branch_control br_ctrl (
        .opcode_i (OPCODE_BRANCH),
        .funct3_i (funct3_i),
        .rs1_i   (rs1_i),
        .rs2_i   (rs2_i),
        .breq_o   (breq_o),
        .brlt_o   (brlt_o)
    );

    // Check if this is a branch instruction based on funct3 values
    logic is_branch;
    always_comb begin
        is_branch = (funct3_i == FUNCT3_BEQ) || 
                   (funct3_i == FUNCT3_BNE) || 
                   (funct3_i == FUNCT3_BLT) || 
                   (funct3_i == FUNCT3_BGE) || 
                   (funct3_i == FUNCT3_BLTU) || 
                   (funct3_i == FUNCT3_BGEU);
    end

    // ALU operation
    always_comb begin
        // Default output
        res_o = 32'd0;
        brtaken_o = 1'b0;

        if (is_branch) begin
            // Branch instructions - calculate branch target address
            res_o = pc_i + rs2_i; // rs2_i should contain the branch offset
            case (funct3_i)
                FUNCT3_BEQ: brtaken_o = breq_o;
                FUNCT3_BNE: brtaken_o = ~breq_o;
                FUNCT3_BLT, FUNCT3_BLTU: brtaken_o = brlt_o;
                FUNCT3_BGE, FUNCT3_BGEU: brtaken_o = ~brlt_o | breq_o;
                default: brtaken_o = 1'b0;
            endcase
        end else begin
            // Arithmetic/Logic instructions
            case (funct3_i)
                FUNCT3_ADD_SUB: begin // ADD/SUB/ADDI
                    if (funct7_i == FUNCT7_SUB) begin
                        res_o = rs1_i - rs2_i; // SUB
                    end else begin
                        res_o = rs1_i + rs2_i; // ADD/ADDI
                    end
                end
                FUNCT3_SLL: begin // SLL/SLLI
                    res_o = rs1_i << rs2_i[4:0];
                end
                FUNCT3_SLT: begin // SLT/SLTI
                    res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : 32'd0;
                end
                FUNCT3_SLTU: begin // SLTU/SLTIU
                    res_o = (rs1_i < rs2_i) ? 32'd1 : 32'd0;
                end
                FUNCT3_XOR: begin // XOR/XORI
                    res_o = rs1_i ^ rs2_i;
                end
                FUNCT3_SRL_SRA: begin // SRL/SRA/SRLI/SRAI
                    if (funct7_i == FUNCT7_SRA) begin
                        res_o = $signed(rs1_i) >>> rs2_i[4:0]; // SRA/SRAI
                    end else begin
                        res_o = rs1_i >> rs2_i[4:0]; // SRL/SRLI
                    end
                end
                FUNCT3_OR: begin // OR/ORI
                    res_o = rs1_i | rs2_i;
                end
                FUNCT3_AND: begin // AND/ANDI
                    res_o = rs1_i & rs2_i;
                end
                default: begin
                    res_o = 32'd0;
                end
            endcase
        end
    end

endmodule : alu
