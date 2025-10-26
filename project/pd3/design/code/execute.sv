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
            // R-type and I-type arithmetic/logical operations
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
                if (funct7_i == FUNCT7_SRA || rs2_i[10] == 1'b1) begin
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

            // Branch instructions
            FUNCT3_BEQ: begin // BEQ
                res_o = pc_i + rs2_i; // Branch target address (rs2_i contains immediate)
                brtaken_o = breq_o;
            end
            FUNCT3_BNE: begin // BNE
                res_o = pc_i + rs2_i; // Branch target address
                brtaken_o = ~breq_o;
            end
            FUNCT3_BLT: begin // BLT
                res_o = pc_i + rs2_i; // Branch target address
                brtaken_o = brlt_o;
            end
            FUNCT3_BGE: begin // BGE
                res_o = pc_i + rs2_i; // Branch target address
                brtaken_o = ~brlt_o | breq_o;
            end
            FUNCT3_BLTU: begin // BLTU
                res_o = pc_i + rs2_i; // Branch target address
                brtaken_o = brlt_o;
            end
            FUNCT3_BGEU: begin // BGEU
                res_o = pc_i + rs2_i; // Branch target address
                brtaken_o = ~brlt_o | breq_o;
            end

            // Load instructions - calculate memory address
            FUNCT3_LB, FUNCT3_LBU: begin // LB, LBU
                res_o = rs1_i + rs2_i; // Memory address (rs2_i contains immediate)
            end
            FUNCT3_LH, FUNCT3_LHU: begin // LH, LHU
                res_o = rs1_i + rs2_i; // Memory address
            end
            FUNCT3_LW: begin // LW
                res_o = rs1_i + rs2_i; // Memory address
            end

            // Store instructions - calculate memory address
            FUNCT3_SB: begin // SB
                res_o = rs1_i + rs2_i; // Memory address (rs2_i contains immediate)
            end
            FUNCT3_SH: begin // SH
                res_o = rs1_i + rs2_i; // Memory address
            end
            FUNCT3_SW: begin // SW
                res_o = rs1_i + rs2_i; // Memory address
            end

            default: begin
                res_o = 32'd0;
                brtaken_o = 1'b0;
            end
        endcase
    end

    // Handle special cases based on funct7 for other instruction types
    // This logic assumes the controlling unit passes appropriate values in rs2_i
    always_comb begin
        // Special handling for JAL, JALR, LUI, AUIPC would be done by the control unit
        // by setting appropriate values in the inputs and using specific funct3/funct7 combinations
        
        // For JAL: control unit sets rs2_i to immediate, res_o = pc_i + 4 returned
        if (funct7_i == 7'b1101111) begin // JAL opcode in funct7 (non-standard but works with current interface)
            res_o = pc_i + 32'd4; // Return address
            brtaken_o = 1'b1;
        end
        
        // For JALR: control unit sets rs2_i to immediate, res_o = pc_i + 4 returned  
        else if (funct7_i == 7'b1100111) begin // JALR opcode in funct7
            res_o = pc_i + 32'd4; // Return address
            brtaken_o = 1'b1;
        end
        
        // For LUI: control unit passes immediate in rs2_i
        else if (funct7_i == 7'b0110111) begin // LUI opcode in funct7
            res_o = rs2_i; // Load upper immediate (rs2_i contains immediate << 12)
        end
        
        // For AUIPC: control unit passes immediate in rs2_i
        else if (funct7_i == 7'b0010111) begin // AUIPC opcode in funct7
            res_o = pc_i + rs2_i; // Add upper immediate to PC
        end
    end

endmodule : alu
