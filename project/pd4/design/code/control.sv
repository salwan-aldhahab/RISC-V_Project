
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
    output logic [3:0] alusel_o,
    output logic jump_o,
    output logic branch_o,
    output logic [2:0] funct3_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    always_comb begin
        // Start with safe defaults - nothing happens unless we explicitly enable it
        pcsel_o = 1'b0;      // Stay on current PC path
        immsel_o = 1'b0;     // Use register data, not immediate
        regwren_o = 1'b0;    // Don't write to registers
        rs1sel_o = 1'b0;     // Select rs1 register
        rs2sel_o = 1'b0;     // Select rs2 register
        memren_o = 1'b0;     // No memory reads
        memwren_o = 1'b0;    // No memory writes
        wbsel_o = 2'b00;     // Default writeback source is ALU
        alusel_o = ALU_ADD;  // Default ALU operation is addition
        jump_o = 1'b0;
        branch_o = 1'b0;
        funct3_o = funct3_i;

        // Decode the instruction based on its opcode
        case (opcode_i)
            
            OPCODE_RTYPE: begin
                regwren_o = 1'b1;    // We'll write the result back to rd
                rs1sel_o = 1'b0;     // Use rs1 register value
                rs2sel_o = 1'b0;     // Use rs2 register value
                immsel_o = 1'b0;     // No immediate needed
                wbsel_o = 2'b00;     // Write back the ALU result

                
                case (funct3_i)
                    FUNCT3_ADD_SUB: begin
                        // Could be ADD or SUB - check funct7 to decide
                        if (funct7_i == FUNCT7_SUB) begin
                            alusel_o = ALU_SUB;  // It's a subtraction
                        end else begin
                            alusel_o = ALU_ADD;  // It's an addition
                        end
                    end
                    FUNCT3_AND: alusel_o = ALU_AND;    // Bitwise AND
                    FUNCT3_OR: alusel_o = ALU_OR;      // Bitwise OR
                    FUNCT3_XOR: alusel_o = ALU_XOR;    // Bitwise XOR
                    FUNCT3_SLL: alusel_o = ALU_SLL;    // Shift left logical
                    FUNCT3_SRL_SRA: begin
                        // Could be logical or arithmetic right shift
                        if (funct7_i == FUNCT7_SRA) begin
                            alusel_o = ALU_SRA;  // Shift right arithmetic
                        end else begin
                            alusel_o = ALU_SRL;  // Shift right logical
                        end
                    end
                    FUNCT3_SLT: alusel_o = ALU_SLT;    // Set less than (signed)
                    FUNCT3_SLTU: alusel_o = ALU_SLTU;  // Set less than (unsigned)
                    default: alusel_o = ALU_ADD;       // Play it safe with ADD
                endcase
            end

            // I-type instructions: immediate operations (addi, andi, ori, etc.)
            OPCODE_ITYPE: begin
                regwren_o = 1'b1;    // Write result to rd
                rs1sel_o = 1'b0;     // Use rs1 register value
                rs2sel_o = 1'b1;     // Use immediate instead of rs2
                immsel_o = 1'b1;     // Enable immediate value
                wbsel_o = 2'b00;     // Write back ALU result

                case (funct3_i)
                    FUNCT3_ADD_SUB: alusel_o = ALU_ADD;  // ADDI (no SUBI in RISC-V)
                    FUNCT3_AND: alusel_o = ALU_AND;      // ANDI
                    FUNCT3_OR: alusel_o = ALU_OR;        // ORI
                    FUNCT3_XOR: alusel_o = ALU_XOR;      // XORI
                    FUNCT3_SLL: alusel_o = ALU_SLL;      // SLLI
                    FUNCT3_SRL_SRA: begin
                        // Immediate shift instructions
                        if (funct7_i == FUNCT7_SRA) begin
                            alusel_o = ALU_SRA;  // SRAI
                        end else begin
                            alusel_o = ALU_SRL;  // SRLI
                        end
                    end
                    FUNCT3_SLT: alusel_o = ALU_SLT;      // SLTI
                    FUNCT3_SLTU: alusel_o = ALU_SLTU;    // SLTIU
                    default: alusel_o = ALU_ADD;         // Default to ADD
                endcase
            end

            // Load instructions: read from memory
            OPCODE_LOAD: begin
                regwren_o = 1'b1;    // Write loaded data to rd
                rs1sel_o = 1'b0;     // Use rs1 as base address
                rs2sel_o = 1'b1;     // Use immediate as offset
                immsel_o = 1'b1;     // Enable immediate for offset
                memren_o = 1'b1;     // Enable memory read
                wbsel_o = 2'b01;     // Write back data from memory
                alusel_o = ALU_ADD;  // Calculate address: rs1 + immediate
            end

            // Store instructions: write to memory
            OPCODE_STORE: begin
                regwren_o = 1'b0;    // Don't write to any register
                rs1sel_o = 1'b0;     // Use rs1 as base address
                rs2sel_o = 1'b1;     // Use immediate as offset
                immsel_o = 1'b1;     // Enable immediate for offset
                memwren_o = 1'b1;    // Enable memory write
                wbsel_o = 2'b00;     // Doesn't matter since we're not writing back
                alusel_o = ALU_ADD;  // Calculate address: rs1 + immediate
            end

            // Branch instructions: conditional jumps
            OPCODE_BRANCH: begin
                regwren_o = 1'b0;    // Branches don't write to registers
                rs1sel_o = 1'b0;     // Use rs1 for comparison
                rs2sel_o = 1'b0;     // Use rs2 for comparison
                immsel_o = 1'b1;     // Immediate holds branch offset
                branch_o = 1'b1;
                pcsel_o = 1'b0;      // Branch unit will decide if we actually branch
                wbsel_o = 2'b00;     // Doesn't matter since no writeback
                alusel_o = ALU_SUB;  // Compare by subtracting: rs1 - rs2
            end

            // JAL: Jump and link (unconditional jump, save return address)
            OPCODE_JAL: begin
                regwren_o = 1'b1;    // Save return address (PC+4) in rd
                rs1sel_o = 1'b1;     // Don't need rs1
                rs2sel_o = 1'b1;     // Don't need rs2
                immsel_o = 1'b1;     // Jump offset is in immediate
                pcsel_o = 1'b1;      // Take the jump
                jump_o = 1'b1;
                wbsel_o = 2'b10;     // Write back PC+4 (return address)
                alusel_o = ALU_ADD;  // ALU not really used here
            end

            // JALR: Jump and link register (jump to rs1+imm, save return address)
            OPCODE_JALR: begin
                regwren_o = 1'b1;    // Save return address (PC+4) in rd
                rs1sel_o = 1'b0;     // Use rs1 as base for jump target
                rs2sel_o = 1'b1;     // Use immediate as offset
                immsel_o = 1'b1;     // Immediate is jump offset
                pcsel_o = 1'b1;      // Take the jump
                jump_o = 1'b1;
                wbsel_o = 2'b10;     // Write back PC+4 (return address)
                alusel_o = ALU_ADD;  // Calculate jump target: rs1 + immediate
            end

            // LUI: Load upper immediate (load 20-bit immediate into upper bits of rd)
            OPCODE_LUI: begin
                regwren_o = 1'b1;    // Write result to rd
                rs1sel_o = 1'b1;     // Don't need rs1
                rs2sel_o = 1'b1;     // Don't need rs2
                immsel_o = 1'b1;     // Use the immediate value
                wbsel_o = 2'b00;     // Write back ALU result
                alusel_o = ALU_LUI;  // Special LUI operation
            end

            // AUIPC: Add upper immediate to PC
            OPCODE_AUIPC: begin
                regwren_o = 1'b1;    // Write result to rd
                rs1sel_o = 1'b1;     // Don't use rs1 (PC is used instead)
                rs2sel_o = 1'b1;     // Don't need rs2
                immsel_o = 1'b1;     // Use immediate value
                wbsel_o = 2'b00;     // Write back ALU result
                alusel_o = ALU_AUIPC; // Special AUIPC operation
            end

            // Safety net: if we see an opcode we don't recognize, do nothing
            default: begin
                pcsel_o = 1'b0;      // Don't change PC
                immsel_o = 1'b0;     // Don't use immediate
                regwren_o = 1'b0;    // Don't write to registers
                rs1sel_o = 1'b0;     // Default register selections
                rs2sel_o = 1'b0;     
                memren_o = 1'b0;     // No memory operations
                memwren_o = 1'b0;    
                wbsel_o = 2'b00;     // Default writeback
                alusel_o = ALU_ADD;  // Safe ALU operation
            end
        endcase
    end

endmodule : control
