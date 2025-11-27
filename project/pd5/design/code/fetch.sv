/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) stall_i - stall signal from hazard unit
 * 4) pcsel_i - PC select (0 = PC+4, 1 = branch target)
 * 5) pctarget_i - branch/jump target address
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o
 */

module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
)(
    input logic clk,
    input logic rst,
    input logic stall_i,
    input logic pcsel_i,
    input logic [AWIDTH-1:0] pctarget_i,
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o
);
    
    logic [AWIDTH - 1:0] pc;
      
    always_ff @(posedge clk) begin 
        if (rst) begin
            pc <= BASEADDR;
        end else if (pcsel_i) begin
            // Branch/jump takes highest priority - always update PC
            pc <= pctarget_i;
        end else if (!stall_i) begin
            // Normal increment only when not stalling
            pc <= pc + 32'd4;
        end
        // When stall_i is high and no branch, pc holds its value
    end
       
    assign pc_o = pc;
endmodule : fetch