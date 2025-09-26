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
logic [AWIDTH-1:0] f_pc;
logic [DWIDTH-1:0] f_insn;

// probes instantiation for memory interface
logic [AWIDTH-1:0] addr;
logic [DWIDTH-1:0] data_in;
logic [DWIDTH-1:0] data_out;
logic read_en;
logic write_en;

// fetch module instantiation
fetch #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH),
    .BASEADDR(32'h01000000)
) f (
    .clk(clk),
    .rst(reset),
    .pc_o(f_pc),
    .insn_o(f_insn)
);

// memory module instantiation
memory #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH),
    .BASE_ADDR(32'h01000000)
) imem (
    .clk(clk),
    .rst(reset),
    .addr_i(addr),
    .data_i(data_in),
    .read_en_i(read_en),
    .write_en_i(write_en),
    .data_o(data_out)
);

endmodule : pd1
