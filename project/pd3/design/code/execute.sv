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

    /*
     * Process definitions to be filled by
     * student below...
     */

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

    // ALU operation
    always_comb begin
        // Default output
        res_o = 32'd0;
        brtaken_o = 1'b0;

        case (funct3_i)
            FUNCT3_ADD_SUB: begin // ADD/SUB
                if (funct7_i == FUNCT7_SUB) begin
                    res_o = rs1_i - rs2_i; // SUB
                end else begin
                    res_o = rs1_i + rs2_i; // ADD
                end
            end
            FUNCT3_SLL: begin
                res_o = rs1_i << rs2_i[4:0];
            end
            FUNCT3_SLT: begin // SLT
                res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : 32'd0;
            end
            FUNCT3_SLTU: begin // SLTU
                res_o = (rs1_i < rs2_i) ? 32'd1 : 32'd0;
            end
            FUNCT3_XOR: begin // XOR
                res_o = rs1_i ^ rs2_i;
            end
            FUNCT3_SRL_SRA: begin
                if (funct7_i == FUNCT7_SRA) begin
                    res_o = $signed(rs1_i) >>> rs2_i[4:0]; // SRA
                end else begin
                    res_o = rs1_i >> rs2_i[4:0]; // SRL
                end
            end
            FUNCT3_OR: begin // OR
                res_o = rs1_i | rs2_i;
            end
            FUNCT3_AND: begin // AND
                res_o = rs1_i & rs2_i;
            end
            FUNCT3_BEQ: begin // BEQ
                brtaken_o = breq_o;
            end
            FUNCT3_BNE: begin // BNE
                brtaken_o = ~breq_o;
            end
            FUNCT3_BLT, FUNCT3_BLTU: begin // BLT, BLTU
                brtaken_o = brlt_o;
            end
            FUNCT3_BGE, FUNCT3_BGEU: begin // BGE, BGEU
                brtaken_o = ~brlt_o | breq_o; // greater than or equal
            end
            default: begin
                res_o = 32'd0;
                brtaken_o = 1'b0;
            end
        endcase
    end

endmodule : alu
