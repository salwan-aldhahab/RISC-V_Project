/*
 * Module: pd1
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd1 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */

// probes institiation for fetch stage
logic [AWIDTH-1:0] f_pc
logic [DWIDTH-1:0] f_insn

// probes instantiation for memory interface
logic [AWIDTH-1:0] addr;
logic [DWIDTH-1:0] data_in;
logic [DWIDTH-1:0] data_out;
logic read_en;
logic write_en;

// fetch module instantiation
fetch #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
) f (
    .clk(clk),
    .rst(reset),
    .pc_o(f_pc),
    .insn_o(f_insn)
);

// connect fetch outputs to memory inputs
assign addr = f_pc;
assign data_out = f_insn;

assign data_in = '0;  // no data to write from fetch
assign read_en = 1'b1; // fetch always reads instructions
assign write_en = 1'b0; // fetch never writes


endmodule : pd1
