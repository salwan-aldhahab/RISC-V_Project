/*
 * Module: writeback
 *
 * Description: Write-back control stage implementation
 *
 * Inputs:
 * 1) PC pc_i
 * 2) result from alu alu_res_i
 * 3) data from memory memory_data_i
 * 4) data to select for write-back wbsel_i
 * 5) branch taken signal brtaken_i
 *
 * Outputs:
 * 1) DWIDTH wide write back data write_data_o
 * 2) AWIDTH wide next computed PC next_pc_o
 */

 module writeback #(
     parameter int DWIDTH=32,
     parameter int AWIDTH=32
 )(
     input logic [AWIDTH-1:0] pc_i,
     input logic [DWIDTH-1:0] alu_res_i,
     input logic [DWIDTH-1:0] memory_data_i,
     input logic [1:0] wbsel_i,
     input logic brtaken_i,
     output logic [DWIDTH-1:0] writeback_data_o,
     output logic [AWIDTH-1:0] next_pc_o
 );

    /*
     * Process definitions to be filled by
     * student below...
     */
    
    // Write-back data selection logic
    always_comb begin
        case (wbsel_i)
            2'b00: begin
                writeback_data_o = alu_res_i;          // From ALU
            end
            2'b01: begin
                writeback_data_o = memory_data_i;     // From Memory
            end
            2'b10: begin
                writeback_data_o = pc_i + 4;          // From PC + 4
            end
            default: begin
                writeback_data_o = '0;               // Default case
            end
        endcase
    end

    // Next PC computation logic
    always_comb begin
        if (brtaken_i || wbsel_i == 2'b10) begin
            next_pc_o = alu_res_i;  // Branch taken, next PC from ALU result
        end else begin
            next_pc_o = pc_i + 4;   // Sequential execution, next PC is PC + 4
        end
    end

endmodule : writeback