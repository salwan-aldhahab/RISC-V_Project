/*
 * Module: pd0
 *
 * Description: Top level module that will contain sub-module instantiations.
 * An instantiation of the assign_xor module is shown as an example. The other
 * modules must be instantiated similarly. Probes are defined, which will be used
 * to test This file also defines probes that will be used to test the design. Note
 * that the top level module should have only two inputs: clk and rest signals.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */
 
`include "probes.svh"
import constants_pkg::*;

module pd0 #(
    parameter int DWIDTH = 32)
 (
    input logic clk,
    input logic reset
    );

 // Probes that will be defined in probes.svh
 logic assign_xor_op1;
 logic assign_xor_op2;
 logic assign_xor_res;

 assign_xor assign_xor_0 (
     .op1_i (assign_xor_op1),
     .op2_i (assign_xor_op2),
     .res_o (assign_xor_res)
 );

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */

  // ALU
 logic [DWIDTH-1:0] `PROBE_ALU_OP1;
 logic [DWIDTH-1:0] `PROBE_ALU_OP2;
 logic [DWIDTH-1:0] `PROBE_ALU_RES;
 logic [1:0]        `PROBE_ALU_SEL;

 // Register
 logic [DWIDTH-1:0] `PROBE_REG_IN;
 logic [DWIDTH-1:0] `PROBE_REG_OUT;

 // Three-stage pipeline
 logic [DWIDTH-1:0] `PROBE_TSP_OP1;
 logic [DWIDTH-1:0] `PROBE_TSP_OP2;
 logic [DWIDTH-1:0] `PROBE_TSP_RES;

  
 logic alu_zero, alu_neg;

 alu #(.DWIDTH(DWIDTH)) unit_alu (
   .sel_i (`PROBE_ALU_SEL),
   .op1_i (`PROBE_ALU_OP1),
   .op2_i (`PROBE_ALU_OP2),
   .res_o (`PROBE_ALU_RES),
   .zero_o (alu_zero),
   .neg_o (alu_neg)
 );

 reg_rst #(.DWIDTH(DWIDTH)) unit_reg_rst (
   .clk (clk),
   .rst (reset),
   .in_i (`PROBE_REG_IN),
   .out_o (`PROBE_REG_OUT)
 );

 three_stage_pipeline #(.DWIDTH(DWIDTH)) unit_tsp (
   .clk (clk),
   .rst (reset),
   .op1_i (`PROBE_TSP_OP1),
   .op2_i (`PROBE_TSP_OP2),
   .res_o (`PROBE_TSP_RES)
 );

 endmodule: pd0