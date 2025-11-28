/*
 * Module: register_file
 *
 * Description: Register file 
 *
 * -------- REPLACE THIS FILE WITH THE RF MODULE DEVELOPED IN PD4 -----------
 *
 */

/*
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) clk
 * 2) reset signal rst
 * 3) 5-bit rs1 address rs1_i
 * 4) 5-bit rs2 address rs2_i
 * 5) 5-bit rd address rd_i
 * 6) DWIDTH-wide data writeback datawb_i
 * 7) register write enable regwren_i
 * Outputs:
 * 1) 32-bit rs1 data rs1data_o
 * 2) 32-bit rs2 data rs2data_o
 */

`include "constants.svh"

 module register_file #(
     parameter int DWIDTH=32
 )(
     // inputs
     input logic clk,
     input logic rst,
     input logic [4:0] rs1_i,
     input logic [4:0] rs2_i,
     input logic [4:0] rd_i,
     input logic [DWIDTH-1:0] datawb_i,  // data to write back
     input logic regwren_i, // register write enable
     // outputs
     output logic [DWIDTH-1:0] rs1data_o,
     output logic [DWIDTH-1:0] rs2data_o
 );

    /*
     * Process definitions to be filled by
     * student below...
     */

    // Where the stack starts
    logic [DWIDTH-1:0] stack_pointer = 32'h0110_0000;

    // Our 32 register storage think of them as numbered boxes 0-31
    logic [DWIDTH-1:0] registers [31:0];

    // Reading registers - latched on falling edge for same-cycle forwarding
    logic [DWIDTH-1:0] rs1data_reg, rs2data_reg;
    
    always_ff @(negedge clk) begin
        rs1data_reg <= (rs1_i != 0) ? registers[rs1_i] : '0;
        rs2data_reg <= (rs2_i != 0) ? registers[rs2_i] : '0;
    end
    
    assign rs1data_o = rs1data_reg;
    assign rs2data_o = rs2data_reg;

    // Writing happens every clock tick
    always_ff @(posedge clk) begin
        if (rst) begin
            //clear everything and set up stack pointer
            for (int i = 0; i < 32; i++) begin
                registers[i] <= '0;
            end
            registers[2] <= stack_pointer; // x2 = stack pointer
        end else begin
            // Normal write: save data but never to x0 (it's read-only)
            if (regwren_i && rd_i != 5'd0) begin
                registers[rd_i] <= datawb_i;
            end
            // Force x0 to stay zero no matter what
            registers[0] <= '0;
        end
    end
endmodule : register_file