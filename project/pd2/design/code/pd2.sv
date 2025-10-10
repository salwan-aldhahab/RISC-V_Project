/*
 * Module: pd2
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd2 #(
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
  
  // -- Probes Instantiation --

  // Fetch stage signals
  logic [DWIDTH-1:0] f_pc, f_insn;

  // Decode stage signals
  logic [DWIDTH-1:0] d_pc, d_insn;
  logic [6:0] d_opcode;
  logic [4:0] d_rd, d_rs1, d_rs2;
  logic [6:0] d_funct7;
  logic [2:0] d_funct3;
  logic [DWIDTH-1:0] d_imm;
  logic [4:0] d_shamt;

  // -- Probes Instantiation --


  // imemory signals
  logic [DWIDTH - 1:0] addr_i;
  logic [DWIDTH - 1:0] data_i;
  logic write_en;
  logic read_en;
  
  assign read_en = 1'b1;
  assign write_en = 1'b0;

  memory #(
      .AWIDTH(32),
      .DWIDTH(32),
      .BASE_ADDR(32'h01000000)
  ) memory1 (
      .clk(clk),
      .rst(reset),
      .addr_i(f_pc),
      .data_i(data_i),
      .read_en_i(read_en),
      .write_en_i(write_en),
      .data_o(f_insn)
  );

  // Fetch
  fetch #(
      .AWIDTH(32),
      .DWIDTH(32),
      .BASEADDR(32'h01000000)
  ) fetch1 (
      .clk(clk),
      .rst(reset),
      .pc_o(f_pc),            
      .insn_o(f_insn)         
  );


  // Decode
  decode #( .AWIDTH(AWIDTH), .DWIDTH(DWIDTH) ) decode_stage (
      .clk(clk),
      .rst(reset),
      .insn_i(f_insn),
      .pc_i(f_pc),
      .pc_o(d_pc),
      .insn_o(d_insn),
      .opcode_o(d_opcode),
      .rd_o(d_rd),
      .rs1_o(d_rs1),
      .rs2_o(d_rs2),
      .funct7_o(d_funct7),
      .funct3_o(d_funct3),
      .imm_o(d_imm),
      .shamt_o(d_shamt)
  );

  // Control
  logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
  logic [1:0] wbsel;
  logic [3:0] alusel;
  control #( .DWIDTH(DWIDTH) ) control_unit (
      .insn_i(d_insn),
      .opcode_i(d_opcode),
      .funct7_i(d_funct7),
      .funct3_i(d_funct3),
      .pcsel_o(pcsel),
      .immsel_o(immsel),
      .regwren_o(regwren),
      .rs1sel_o(rs1sel),
      .rs2sel_o(rs2sel),
      .memren_o(memren),
      .memwren_o(memwren),
      .wbsel_o(wbsel),
      .alusel_o(alusel)
  );

endmodule : pd2
