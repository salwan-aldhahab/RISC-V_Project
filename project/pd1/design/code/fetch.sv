/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
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
    // inputs
    input logic clk,
    input logic rst,
    // outputs	
    output logic [AWIDTH - 1:0] pc_o,
    output logic [DWIDTH - 1:0] insn_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */
    
    // Program Counter register
    logic [AWIDTH-1:0] pc_reg;
    
    // Memory interface signals
    logic mem_read_en;
    logic mem_write_en;
    logic [DWIDTH-1:0] mem_data_in;
    logic [DWIDTH-1:0] mem_data_out;
    
    // Program Counter logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= BASEADDR;  // Reset PC to base address
        end else begin
            pc_reg <= pc_reg + 4;  // Increment PC by 4 (word size)
        end
    end
    
    // Output the current PC
    assign pc_o = pc_reg;
    
    // Memory control signals for instruction fetch
    assign mem_read_en = 1'b1;      // Always reading instructions
    assign mem_write_en = 1'b0;     // Never writing in fetch stage
    assign mem_data_in = '0;        // No data to write
    
    // Instantiate memory module for instruction memory
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASEADDR)
    ) instruction_memory (
        .clk(clk),
        .rst(rst),
        .addr_i(pc_reg),
        .data_i(mem_data_in),
        .read_en_i(mem_read_en),
        .write_en_i(mem_write_en),
        .data_o(mem_data_out)
    );

    // Output the fetched instruction
    assign insn_o = mem_data_out;

endmodule : fetch