/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * Inputs:
 * 1) DWIDTH instruction ins_i
 * 2) 7-bit opcode opcode_i
 * 3) 7-bit funct7 funct7_i
 * 4) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
 */

`include "constants.svh"

module control #(
	parameter int DWIDTH=32
)(
	// inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    // outputs
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o,
    output logic rs2sel_o,
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o,
    output logic [3:0] alusel_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    always_comb begin
        // Default values for control signals
        pcsel_o = 1'b0;
        immsel_o = 1'b0;
        regwren_o = 1'b0;
        rs1sel_o = 1'b0;
        rs2sel_o = 1'b0;
        memren_o = 1'b0;
        memwren_o = 1'b0;
        wbsel_o = 2'b00; // Default to ALU result
        alusel_o = ALU_ADD; // Default ALU operation

        case (opcode_i)
            OPCODE_RTYPE: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b0;
                immsel_o = 1'b0;
                wbsel_o = 2'b00; // Write back ALU result

                case (funct3_i)
                    FUNCT3_ADD_SUB: begin
                        if (funct7_i == FUNCT7_SUB) begin
                            alusel_o = ALU_SUB; // SUB operation
                        end else begin
                            alusel_o = ALU_ADD; // ADD operation
                        end
                    end
                    FUNCT3_AND: alusel_o = ALU_AND; // AND operation
                    FUNCT3_OR: alusel_o = ALU_OR;   // OR operation
                    FUNCT3_XOR: alusel_o = ALU_XOR; // XOR operation
                    FUNCT3_SLL: alusel_o = ALU_SLL; // SLL operation
                    FUNCT3_SRL_SRA: begin
                        if (funct7_i == FUNCT7_SRA) begin
                            alusel_o = ALU_SRA; // SRA operation
                        end else begin
                            alusel_o = ALU_SRL; // SRL operation
                        end
                    end
                    FUNCT3_SLT: alusel_o = ALU_SLT; // SLT operation
                    FUNCT3_SLTU: alusel_o = ALU_SLTU; // SLTU operation
                    default: alusel_o = ALU_ADD; // Default to ADD for safety
                endcase
            end

            OPCODE_ITYPE: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b1; // Use immediate
                immsel_o = 1'b1; // Immediate selected
                wbsel_o = 2'b00; // Write back ALU result
                case (funct3_i)
                    FUNCT3_ADD_SUB: alusel_o = ALU_ADD; // ADDI operation
                    FUNCT3_AND: alusel_o = ALU_AND; // ANDI operation
                    FUNCT3_OR: alusel_o = ALU_OR;   // ORI operation
                    FUNCT3_XOR: alusel_o = ALU_XOR; // XORI operation
                    FUNCT3_SLL: alusel_o = ALU_SLL; // SLLI operation
                    FUNCT3_SRL_SRA: begin
                        if (funct7_i == FUNCT7_SRA) begin
                            alusel_o = ALU_SRA; // SRAI operation
                        end else begin
                            alusel_o = ALU_SRL; // SRLI operation
                        end
                    end
                    FUNCT3_SLT: alusel_o = ALU_SLT; // SLTI operation
                    FUNCT3_SLTU: alusel_o = ALU_SLTU; // SLTIU operation
                    default: alusel_o = ALU_ADD; // Default to ADD for safety
                endcase
            end

            OPCODE_LOAD: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b1; // Use immediate
                immsel_o = 1'b1; // Immediate selected
                memren_o = 1'b1; // Enable memory read
                wbsel_o = 2'b01; // Write back memory data
                alusel_o = ALU_ADD; // Address calculation
            end

            OPCODE_STORE: begin
                regwren_o = 1'b0;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b0;
                immsel_o = 1'b1; // Immediate selected
                memwren_o = 1'b1; // Enable memory write
                alusel_o = ALU_ADD; // Address calculation
            end

            OPCODE_BRANCH: begin
                regwren_o = 1'b0;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b0;
                immsel_o = 1'b1; // Immediate selected
                pcsel_o = 1'b1; // Branch taken (for simplicity, actual implementation may vary)
                alusel_o = ALU_SUB; // For comparison
            end

            OPCODE_JAL: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b1; // Not used
                rs2sel_o = 1'b1; // Not used
                immsel_o = 1'b1; // Immediate selected
                pcsel_o = 1'b1; // Jump taken
                wbsel_o = 2'b10; // Write back PC+4
                alusel_o = ALU_ADD; // For address calculation
            end
            
            OPCODE_JALR: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b1; // Use immediate
                immsel_o = 1'b1; // Immediate selected
                pcsel_o = 1'b1; // Jump taken
                wbsel_o = 2'b10; // Write back PC+4
                alusel_o = ALU_ADD; // For address calculation
            end
            OPCODE_LUI: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b1; // Not used
                rs2sel_o = 1'b1; // Not used
                immsel_o = 1'b1; // Immediate selected
                wbsel_o = 2'b00; // Write back ALU result
                alusel_o = ALU_LUI; // LUI operation
            end
            OPCODE_AUIPC: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b1; // Not used
                rs2sel_o = 1'b1; // Not used
                immsel_o = 1'b1; // Immediate selected
                wbsel_o = 2'b00; // Write back ALU result
                alusel_o = ALU_AUIPC; // AUIPC operation
            end
            default: begin
                // For unrecognized opcodes, disable all operations
                regwren_o = 1'b0;
                rs1sel_o = 1'b0;
                rs2sel_o = 1'b0;
                immsel_o = 1'b0;
                memren_o = 1'b0;
                memwren_o = 1'b0;
                wbsel_o = 2'b00;
                alusel_o = ALU_ADD; // Default ALU operation
            end
        endcase
    end

endmodule : control
