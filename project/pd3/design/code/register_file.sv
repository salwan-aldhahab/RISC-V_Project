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

    // Stack pointer initial value
    logic [DWIDTH-1:0] stack_pointer = 32'h0110_0000;

    // 32 registers of DWIDTH bits each
    logic [DWIDTH-1:0] registers [31:0];

    assign rs1data_o = (rs1_i != 0) ? registers[rs1_i] : '0;
    assign rs2data_o = (rs2_i != 0) ? registers[rs2_i] : '0;

    // Writeback logic with stack pointer management
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= '0;
            end
            registers[2] <= stack_pointer; // Initialize stack pointer (x2) high -> stack grows down
        end else begin
            if (regwren_i && rd_i != 5'd0) begin // Only write if rd is not x0
                registers[rd_i] <= datawb_i;
            end
            // x0 is hardwired to 0 - no need to explicitly set it since we prevent writes to it
        end
    end
endmodule : register_file
