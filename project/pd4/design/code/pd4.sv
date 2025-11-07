/*
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd4 #(
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

  // Fetch Stage Probes
  logic [AWIDTH-1:0] f_pc;
  logic [DWIDTH-1:0] f_insn;

  // Decode Stage Probes
  logic [AWIDTH-1:0] d_pc;
  logic [6:0]        d_opcode;
  logic [4:0]        d_rd;
  logic [2:0]        d_funct3;
  logic [4:0]        d_rs1;
  logic [4:0]        d_rs2;
  logic [6:0]        d_funct7;
  logic [31:0]       d_imm;
  logic [4:0]        d_shamt;

  // Register Stage Probes
  logic              r_write_enable;
  logic [4:0]        r_write_destination;
  logic [DWIDTH-1:0] r_write_data;
  logic [4:0]        r_read_rs1;
  logic [4:0]        r_read_rs2;
  logic [DWIDTH-1:0] r_read_rs1_data;
  logic [DWIDTH-1:0] r_read_rs2_data;

  // Execute Stage Probes
  logic [AWIDTH-1:0] e_pc;
  logic [DWIDTH-1:0] e_alu_res;
  logic              e_br_taken;

  // Memory Stage Probes
  logic [AWIDTH-1:0] m_pc;
  logic [DWIDTH-1:0] m_address;
  logic [1:0]        m_size_encoded;
  logic [DWIDTH-1:0] m_data;

  // Writeback Stage Probes
  logic [AWIDTH-1:0] w_pc;
  logic              w_enable;
  logic [4:0]        w_destination;
  logic [DWIDTH-1:0] w_data;
  
  // -- End Probes Instantiation --

  // -- Submodule Instantiations --

  // Internal signals
  logic [AWIDTH-1:0] addr_i;
  logic [DWIDTH-1:0] data_i;
  logic write_en;
  logic read_en;
  logic [DWIDTH-1:0] imem_insn_f;
  logic [DWIDTH-1:0] d_insn;
  logic [DWIDTH-1:0] dmem_data_o;
  logic [AWIDTH-1:0] next_pc;
  logic [DWIDTH-1:0] data_out;

  // Control signals
  logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
  logic [1:0] wbsel;
  logic [3:0] alusel;

  // Fetch stage
  fetch #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASEADDR(32'h01000000)
  ) fetch_stage (
      .clk(clk),
      .rst(reset),
      .pcsel_i(pcsel & e_br_taken),
      .pctarget_i(next_pc),
      .pc_o(f_pc),            
      .insn_o()         
  );

  // Instruction Memory (read-only for fetch stage)
  assign addr_i = f_pc;
  assign data_i = '0; // No data to write
  assign read_en = 1'b1;
  assign write_en = 1'b0;

  memory #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
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
  decode #( 
      .AWIDTH(AWIDTH), 
      .DWIDTH(DWIDTH) 
  ) decode_stage (
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

  // Control unit
  control #( 
      .DWIDTH(DWIDTH) 
  ) control_unit (
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

  // Register File - connect to probes
  assign r_read_rs1 = d_rs1;
  assign r_read_rs2 = d_rs2;
  assign r_write_enable = regwren;
  assign r_write_destination = d_rd;

  register_file #( 
      .DWIDTH(DWIDTH) 
  ) reg_file (
      .clk(clk),
      .rst(reset),
      .rs1_i(r_read_rs1),
      .rs2_i(r_read_rs2),
      .rd_i(r_write_destination),
      .datawb_i(r_write_data),
      .regwren_i(r_write_enable),
      .rs1data_o(r_read_rs1_data),
      .rs2data_o(r_read_rs2_data)
  );

  // Execute stage - connect to probes
  assign e_pc = d_pc;

  alu #( 
      .DWIDTH(DWIDTH), 
      .AWIDTH(AWIDTH) 
  ) alu_stage (
      .pc_i(e_pc),
      .rs1_i(r_read_rs1_data),
      .rs2_i(r_read_rs2_data),
      .opcode_i(d_opcode),
      .funct3_i(d_funct3),
      .funct7_i(d_funct7),
      .imm_i(d_imm),
      .res_o(e_alu_res),
      .brtaken_o(e_br_taken)
  );

  // Memory stage - connect to probes
  assign m_pc = e_pc;
  assign m_address = e_alu_res;
  assign m_size_encoded = d_funct3[1:0]; // Size encoding from funct3
  assign m_data = dmem_data_o;

  // Data Memory for load/store operations
  memory #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASE_ADDR(32'h02000000)
  ) dmem (
      .clk(clk),
      .rst(reset),
      .addr_i(m_address),
      .data_i(r_read_rs2_data), // Store data comes from rs2
      .read_en_i(memren),
      .write_en_i(memwren),
      .data_o(dmem_data_o)
  );

  // Writeback stage - connect to probes
  assign w_pc = m_pc;
  assign w_enable = r_write_enable;
  assign w_destination = r_write_destination;
  
  // Writeback stage using writeback module
  writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
  ) writeback_stage (
      .pc_i(m_pc),
      .alu_res_i(e_alu_res),
      .memory_data_i(dmem_data_o),
      .wbsel_i(wbsel),
      .brtaken_i(e_br_taken),
      .writeback_data_o(w_data),
      .next_pc_o(next_pc)
  );

  // Connect writeback data to register file and probe
  assign r_write_data = w_data;

  // Make data_out available for program termination logic
  assign data_out = d_insn;

  // program termination logic
  reg is_program = 0;
  always_ff @(posedge clk) begin
      if (data_out == 32'h00000073) $finish;  // directly terminate if see ecall
      if (data_out == 32'h00008067) is_program = 1;  // if see ret instruction, it is simple program test
      // [TODO] Change register_file_0.registers[2] to the appropriate x2 register based on your module instantiations...
      if (is_program && (reg_file.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
  end

endmodule : pd4
