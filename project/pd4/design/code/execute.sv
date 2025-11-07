/*
 * Module: execute
 *
 * Description: ALU implementation for execute stage.
 *
 * -------- REPLACE THIS FILE WITH THE EXECUTE MODULE DEVELOPED IN PD3 -----------
 */

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
    input logic [DWIDTH-1:0] imm_i,
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

    // Main ALU logic does math and decides what to do
    always_comb begin
        // Start with safe defaults
        res_o = ZERO;
        brtaken_o = 1'b0;

        case (opcode_i)
            OPCODE_RTYPE: begin // R-type: register to register operations
                case (funct3_i)
                    FUNCT3_ADD_SUB: begin // Math: add or subtract
                        if (funct7_i == FUNCT7_SUB)
                            res_o = rs1_i - rs2_i; // SUB
                        else
                            res_o = rs1_i + rs2_i; // ADD
                    end
                    FUNCT3_SLL: res_o = rs1_i << rs2_i[4:0]; // SLL - shift left
                    FUNCT3_SLT: res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : ZERO; // SLT - signed compare
                    FUNCT3_SLTU: res_o = (rs1_i < rs2_i) ? 32'd1 : ZERO; // SLTU - unsigned compare
                    FUNCT3_XOR: res_o = rs1_i ^ rs2_i; // XOR - flip bits
                    FUNCT3_SRL_SRA: begin // Right shift operations
                        if (funct7_i == FUNCT7_SRA)
                            res_o = $signed(rs1_i) >>> rs2_i[4:0]; // SRA - arithmetic (keeps sign)
                        else
                            res_o = rs1_i >> rs2_i[4:0]; // SRL - logical (fills with zeros)
                    end
                    FUNCT3_OR: res_o = rs1_i | rs2_i; // OR - combine bits
                    FUNCT3_AND: res_o = rs1_i & rs2_i; // AND - mask bits
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_ITYPE: begin // I-type: register with immediate operations
                case (funct3_i)
                    FUNCT3_ADD_SUB: res_o = rs1_i + imm_i; // ADDI - add immediate
                    FUNCT3_SLL: res_o = rs1_i << imm_i[4:0]; // SLLI - shift left immediate
                    FUNCT3_SLT: res_o = ($signed(rs1_i) < $signed(imm_i)) ? 32'd1 : ZERO; // SLTI - signed compare immediate
                    FUNCT3_SLTU: res_o = (rs1_i < imm_i) ? 32'd1 : ZERO; // SLTIU - unsigned compare immediate
                    FUNCT3_XOR: res_o = rs1_i ^ imm_i; // XORI - XOR with immediate
                    FUNCT3_SRL_SRA: begin // Shift right with immediate
                        if (imm_i[10] == 1'b1) // Check bit 10 to know which type
                            res_o = $signed(rs1_i) >>> imm_i[4:0]; // SRAI - arithmetic
                        else
                            res_o = rs1_i >> imm_i[4:0]; // SRLI - logical
                    end
                    FUNCT3_OR: res_o = rs1_i | imm_i; // ORI - OR with immediate
                    FUNCT3_AND: res_o = rs1_i & imm_i; // ANDI - AND with immediate
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_LOAD: begin // Load: read from memory
                case (funct3_i)
                    FUNCT3_LB, FUNCT3_LBU, FUNCT3_LH, FUNCT3_LHU, FUNCT3_LW: begin
                        res_o = rs1_i + imm_i; // Calculate where to read from
                    end
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_STORE: begin // Store: write to memory
                case (funct3_i)
                    FUNCT3_SB, FUNCT3_SH, FUNCT3_SW: begin
                        res_o = rs1_i + imm_i; // Calculate where to write to
                    end
                    default: res_o = ZERO;
                endcase
            end

            OPCODE_BRANCH: begin // Branch: maybe jump somewhere else
                res_o = pc_i + imm_i; // Calculate jump target address
                case (funct3_i)
                    FUNCT3_BEQ: brtaken_o = breq_o; // BEQ - jump if equal
                    FUNCT3_BNE: brtaken_o = ~breq_o; // BNE - jump if not equal
                    FUNCT3_BLT: brtaken_o = brlt_o; // BLT - jump if less than
                    FUNCT3_BGE: brtaken_o = ~brlt_o | breq_o; // BGE - jump if greater/equal
                    FUNCT3_BLTU: brtaken_o = brlt_o; // BLTU - jump if less than (unsigned)
                    FUNCT3_BGEU: brtaken_o = ~brlt_o | breq_o; // BGEU - jump if greater/equal (unsigned)
                    default: brtaken_o = 1'b0;
                endcase
            end

            OPCODE_JAL: begin // JAL - unconditional jump
                res_o = pc_i + imm_i; // Jump target address
            end

            OPCODE_JALR: begin // JALR - jump to register + offset
                res_o = rs1_i + imm_i; // Jump target from register
            end

            OPCODE_LUI: begin // LUI - load big number into upper bits
                res_o = imm_i; // Put immediate in upper 20 bits
            end

            OPCODE_AUIPC: begin // AUIPC - add big number to PC
                res_o = pc_i + imm_i; // Add immediate to current address
            end

            default: begin // Unknown instruction - do nothing
                res_o = ZERO;
                brtaken_o = 1'b0;
            end
        endcase
    end

endmodule : alu