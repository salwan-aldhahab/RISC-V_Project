/*
 * Module: pd3
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd3 #(
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
  logic [DWIDTH-1:0] f_insn;
  logic [AWIDTH-1:0] f_pc;

  // Decode stage signals
  logic [AWIDTH-1:0] d_pc;
  logic [6:0] d_opcode;
  logic [4:0] d_rd, d_rs1, d_rs2;
  logic [6:0] d_funct7;
  logic [2:0] d_funct3;
  logic [DWIDTH-1:0] d_imm;
  logic [4:0] d_shamt;

  // Register file signals
  logic r_write_enable;
  logic [4:0] r_write_destination;
  logic [DWIDTH-1:0] r_write_data;
  logic [4:0] r_read_rs1;
  logic [4:0] r_read_rs2;
  logic [DWIDTH-1:0] r_read_rs1_data;
  logic [DWIDTH-1:0] r_read_rs2_data;

  // Execute stage signals
  logic [AWIDTH-1:0] e_pc;
  logic [DWIDTH-1:0] e_alu_res;
  logic e_br_taken;
  // -- Probes Instantiation --

  // imemory signals
  logic [AWIDTH - 1:0] addr_i;
  logic [DWIDTH - 1:0] data_i;
  logic write_en;
  logic read_en;
  logic [DWIDTH - 1:0] imem_insn_f; // instruction

  // Fetch stage
  fetch #(
      .AWIDTH(32),
      .DWIDTH(32),
      .BASEADDR(32'h01000000)
  ) fetch1 (
      .clk(clk),
      .rst(reset),
      .pc_o(f_pc),            
      .insn_o()         
  );

    // Instruction Memory (read-only for fetch stage)
  assign addr_i = f_pc;
  assign data_i = '0; // No data to write
  assign read_en = 1'b1;
  assign write_en = 1'b0;

  memory #(
      .AWIDTH(32),
      .DWIDTH(32),
      .BASE_ADDR(32'h01000000)
  ) imem (
      .clk(clk),
      .rst(reset),
      .addr_i(addr_i),
      .data_i(data_i),
      .read_en_i(read_en),
      .write_en_i(write_en),
      .data_o(imem_insn_f)
  );

  // Connect fetched instruction to fetch stage output
  assign f_insn = imem_insn_f;

  // Decode stage
  logic [DWIDTH-1:0] d_insn;
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

  // Register File
  register_file #( .DWIDTH(DWIDTH) ) reg_file (
      .clk(clk),
      .rst(reset),
      .rs1_i(d_rs1),
      .rs2_i(d_rs2),
      .rd_i(r_write_destination),
      .datawb_i(r_write_data),
      .regwren_i(r_write_enable),
      .rs1data_o(r_read_rs1_data),
      .rs2data_o(r_read_rs2_data)
  );

  // Execute stage
  assign e_pc = d_pc;

  // Multiplexers for ALU inputs based on control signals
  logic [DWIDTH-1:0] alu_operand1, alu_operand2;
  // rs1sel mux: 0 = use rs1 data, 1 = use PC
  assign alu_operand1 = rs1sel ? d_pc : r_read_rs1_data;
  // rs2sel mux: 0 = use rs2 data, 1 = use immediate
  assign alu_operand2 = rs2sel ? d_imm : r_read_rs2_data;

  alu #( .DWIDTH(DWIDTH), .AWIDTH(AWIDTH) ) alu_stage (
      .pc_i(e_pc),
      .rs1_i(alu_operand1),
      .rs2_i(alu_operand2),
      .funct3_i(d_funct3),
      .funct7_i(d_funct7),
      .res_o(e_alu_res),
      .brtaken_o(e_br_taken)
  );

  // Register File writeback connections
  assign r_read_rs1 = d_rs1;
  assign r_read_rs2 = d_rs2;
  assign r_write_enable = regwren;
  assign r_write_destination = d_rd;
  assign r_write_data = 0;
endmodule : pd3
