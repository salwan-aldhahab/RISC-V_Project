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
/*
 * Module: pd1
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal (active-high)
 */

`timescale 1ns/1ps
module pd1 #(
    parameter int AWIDTH   = 32,
    parameter int DWIDTH   = 32,
    parameter int BASEADDR = 32'h0100_0000
)(
    input  logic clk,
    input  logic reset
);

  // ---- Signals exposed for probes.svh ----
  logic [AWIDTH-1:0] addr;       // PROBE_ADDR
  logic [DWIDTH-1:0] data_in;    // PROBE_DATA_IN  (write path)
  logic [DWIDTH-1:0] data_out;   // PROBE_DATA_OUT (read path)
  logic              read_en;    // PROBE_READ_EN
  logic              write_en;   // PROBE_WRITE_EN

  logic [AWIDTH-1:0] f_pc;       // PROBE_F_PC
  logic [DWIDTH-1:0] f_insn;     // PROBE_F_INSN

  // ---- IMEM control: fetch is read-only ----
  assign read_en  = 1'b1;
  assign write_en = 1'b0;
  assign data_in  = '0;

  // ---- Fetch stage (expects external IMEM) ----
  fetch #(
      .AWIDTH   (AWIDTH),
      .DWIDTH   (DWIDTH),
      .BASEADDR (BASEADDR)
  ) u_fetch (
      .clk          (clk),
      .rst          (reset),
      .pc_o         (f_pc),
      .insn_o       (f_insn),

      // IMEM interface
      .imem_addr_o  (addr),
      .imem_rdata_i (data_out)
  );

  // ---- Instruction memory (read-only use here) ----
  memory #(
      .AWIDTH    (AWIDTH),
      .DWIDTH    (DWIDTH),
      .BASE_ADDR (BASEADDR)
  ) u_imem (
      .clk         (clk),
      .rst         (reset),
      .addr_i      (addr),
      .data_i      (data_in),
      .read_en_i   (read_en),
      .write_en_i  (write_en),
      .data_o      (data_out)
  );

endmodule : pd1
    input logic clk,
    input logic reset
);

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */



endmodule : pd1
