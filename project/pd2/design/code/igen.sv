/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * 2) input instruction insn_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */

`include "constants.svh"

module igen #(
    parameter int DWIDTH=32
)(
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    output logic [31:0] imm_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */
    always_comb begin
        case (opcode_i)
            OPCODE_ITYPE, OPCODE_LOAD, OPCODE_JALR: begin
                // I-type immediate
                imm_o = {{20{insn_i[31]}}, insn_i[31:20]};
            end
            OPCODE_STORE: begin
                // S-type immediate
                imm_o = {{20{insn_i[31]}}, insn_i[31:25], insn_i[11:7]};
            end
            OPCODE_BRANCH: begin
                // B-type immediate
                imm_o = {{19{insn_i[31]}}, insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8], 1'b0};
            end
            OPCODE_LUI, OPCODE_AUIPC: begin
                // U-type immediate
                imm_o = {insn_i[31:12], 12'b0};
            end
            OPCODE_JAL: begin
                // J-type immediate: imm[20|10:1|11|19:12]
                imm_o = {{11{insn_i[31]}}, insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};
            end
            default: begin
                imm_o = 32'd0; // Default case to avoid latches
            end
        endcase
    end

endmodule : igen
