/*
 * Module: three_stage_pipeline
 *
 * A 3-stage pipeline (TSP) where the first stage performs an addition of two
 * operands (op1_i, op2_i) and registers the output, and the second stage computes
 * the difference between the output from the first stage and op1_i and registers the
 * output. This means that the output (res_o) must be available two cycles after the
 * corresponding inputs have been observed on the rising clock edge
 *
 * Visually, the circuit should look like this:
 *               <---         Stage 1           --->
 *                                                        <---         Stage 2           --->
 *                                                                                               <--    Stage 3    -->
 *                                    |------------------>|                    |
 * -- op1_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *             | pipeline registers |     | ALU add | --> | pipeline registers |   | ALU sub |-->| pipeline register  | -- res_o -->
 * -- op2_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *
 * Inputs:
 * 1) 1-bit clock signal
 * 2) 1-bit wide synchronous reset
 * 3) DWIDTH-wide input op1_i
 * 4) DWIDTH-wide input op2_i
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 */

import constants_pkg::*;


module three_stage_pipeline #(
parameter int DWIDTH = 8)(
        input logic clk,
        input logic rst,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o
    );

    /*
     * Process definitions to be filled by
     * student below...
     * [HINT] Instantiate the alu and reg_rst modules
     * and set up the necessary connections
     *
     */

    // Stage 1: ALU add

    logic [DWIDTH-1:0] add_res; // results of the ALU add
    logic z_add, n_add;

    alu #(.DWIDTH(DWIDTH)) unit_alu_add (
        .sel_i  (ADD),
        .op1_i  (op1_i),
        .op2_i  (op2_i),
        .res_o  (add_res),
        .zero_o (z_add),
        .neg_o  (n_add)
    );

    // Stage 2: pipeline registers + ALU sub
    // Register the results from ALU add
    // Register op1_i to align with the registered ALU add results
    
    logic [DWIDTH-1:0] add_res_reg;
    logic [DWIDTH-1:0] op1_fwd_reg;

    // Register ADD result
    reg_rst #(.DWIDTH(DWIDTH)) unit_add_res_reg (
        .clk   (clk),
        .rst   (rst),
        .in_i  (add_res),
        .out_o (add_res_reg)
    );

    // Forward aligned op1 register
    reg_rst #(.DWIDTH(DWIDTH)) unit_op1_fwd_reg (
        .clk   (clk),
        .rst   (rst),
        .in_i  (op1_i),
        .out_o (op1_fwd_reg)
    );

    logic [DWIDTH-1:0] sub_res;
    logic z_sub, n_sub;

    alu #(.DWIDTH(DWIDTH)) unit_alu_sub (
        .sel_i  (SUB),
        .op1_i  (add_res_reg), 
        .op2_i  (op1_fwd_reg),
        .res_o  (sub_res),
        .zero_o (z_sub),
        .neg_o  (n_sub)
    );

    // Stage 3: Final output register
    // Registers the SUB result so res_o appears two cycles after inputs
    
    reg_rst #(.DWIDTH(DWIDTH)) unit_res_reg (
        .clk   (clk),
        .rst   (rst),
        .in_i  (sub_res),
        .out_o (res_o)
    );

endmodule: three_stage_pipeline
