/*
 * Module: pd5
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd5 #(
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
  logic [AWIDTH-1:0] probe_f_pc;
  logic [DWIDTH-1:0] probe_f_insn;

  // Decode Stage Probes
  logic [AWIDTH-1:0] probe_d_pc;
  logic [6:0]        probe_d_opcode;
  logic [4:0]        probe_d_rd;
  logic [2:0]        probe_d_funct3;
  logic [4:0]        probe_d_rs1;
  logic [4:0]        probe_d_rs2;
  logic [6:0]        probe_d_funct7;
  logic [31:0]       probe_d_imm;
  logic [4:0]        probe_d_shamt;

  // Register Stage Probes
  logic              probe_r_write_enable;
  logic [4:0]        probe_r_write_destination;
  logic [DWIDTH-1:0] probe_r_write_data;
  logic [4:0]        probe_r_read_rs1;
  logic [4:0]        probe_r_read_rs2;
  logic [DWIDTH-1:0] probe_r_read_rs1_data;
  logic [DWIDTH-1:0] probe_r_read_rs2_data;

  // Execute Stage Probes
  logic [AWIDTH-1:0] probe_e_pc;
  logic [DWIDTH-1:0] probe_e_alu_res;
  logic              probe_e_br_taken;

  // Memory Stage Probes
  logic [AWIDTH-1:0] probe_m_pc;
  logic [DWIDTH-1:0] probe_m_address;
  logic [1:0]        probe_m_size_encoded;
  logic [DWIDTH-1:0] probe_m_data;

  // Writeback Stage Probes
  logic [AWIDTH-1:0] probe_w_pc;
  logic              probe_w_enable;
  logic [4:0]        probe_w_destination;
  logic [DWIDTH-1:0] probe_w_data;
  
  // -- End Probes Instantiation --

  // Internal signals
  logic [DWIDTH-1:0] d_insn;
  logic [AWIDTH-1:0] next_pc;
  logic [DWIDTH-1:0] data_out;

  // Control signals that determine datapath behavior
  logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
  logic [1:0] wbsel;
  logic [3:0] alusel;

  // Data coming back from memory reads
  logic [DWIDTH-1:0] dmem_data_o;

  // Raw outputs from the register file before any forwarding
  logic [DWIDTH-1:0] rf_rs1data_raw;
  logic [DWIDTH-1:0] rf_rs2data_raw;

  // Fetch stage - grabs instructions from memory
  fetch #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASEADDR(32'h01000000)
  ) fetch_stage (
      .clk(clk),
      .rst(reset),
      .pcsel_i(pcsel || e_br_taken),
      .pctarget_i(next_pc),
      .pc_o(probe_f_pc),            
      .insn_o()
  );

  // Instruction memory - stores the program we're running
  memory #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASE_ADDR(32'h01000000)
  ) imem (
      .clk(clk),
      .rst(reset),
      .addr_i(probe_f_pc),
      .data_i(32'h00000000),
      .read_en_i(1'b1),
      .write_en_i(1'b0),
      .funct3_i(FUNCT3_LW),
      .data_o(probe_f_insn)
  );

  // Decode stage - breaks instructions into their components
  decode #( 
      .AWIDTH(AWIDTH), 
      .DWIDTH(DWIDTH) 
  ) decode_stage (
      .clk(clk),
      .rst(reset),
      .insn_i(probe_f_insn),
      .pc_i(probe_f_pc),
      .pc_o(probe_d_pc),
      .insn_o(d_insn),
      .opcode_o(probe_d_opcode),
      .rd_o(probe_d_rd),
      .rs1_o(probe_d_rs1),
      .rs2_o(probe_d_rs2),
      .funct7_o(probe_d_funct7),
      .funct3_o(probe_d_funct3),
      .imm_o(probe_d_imm),
      .shamt_o(probe_d_shamt)
  );

  // Control unit - figures out what each instruction needs to do
  control #( 
      .DWIDTH(DWIDTH) 
  ) control_unit (
      .insn_i(d_insn),
      .opcode_i(probe_d_opcode),
      .funct7_i(probe_d_funct7),
      .funct3_i(probe_d_funct3),
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

  // Read addresses tell us which registers to look at
  assign probe_r_read_rs1 = probe_d_rs1;
  assign probe_r_read_rs2 = probe_d_rs2;
  // Write signals control updating registers with new values
  assign probe_r_write_enable = regwren;
  assign probe_r_write_destination = probe_d_rd;

  register_file #( 
      .DWIDTH(DWIDTH) 
  ) reg_file (
      .clk(clk),
      .rst(reset),
      .rs1_i(probe_r_read_rs1),
      .rs2_i(probe_r_read_rs2),
      .rd_i(probe_r_write_destination),
      .datawb_i(probe_r_write_data),
      .regwren_i(probe_r_write_enable),
      .rs1data_o(rf_rs1data_raw),
      .rs2data_o(rf_rs2data_raw)
  );

  // Execute stage - where the actual computation happens
  assign probe_e_pc = probe_d_pc;

  // Connect register outputs directly to the probe signals
  assign probe_r_read_rs1_data = rf_rs1data_raw;
  assign probe_r_read_rs2_data = rf_rs2data_raw;

  alu #( 
      .DWIDTH(DWIDTH), 
      .AWIDTH(AWIDTH) 
  ) alu_stage (
      .pc_i(probe_e_pc),
      .rs1_i(rf_rs1data_raw),
      .rs2_i(rf_rs2data_raw),
      .imm_i(probe_d_imm),
      .opcode_i(probe_d_opcode),
      .funct3_i(probe_d_funct3),
      .funct7_i(probe_d_funct7),
      .res_o(probe_e_alu_res),
      .brtaken_o(probe_e_br_taken)
  );

  // Data memory - where we read and write program data
  memory #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASE_ADDR(32'h01000000)
  ) dmem (
      .clk(clk),
      .rst(reset),
      .addr_i(probe_e_alu_res),
      .data_i(rf_rs2data_raw),
      .read_en_i(1'b1),
      .write_en_i(memwren),
      .funct3_i(memwren ? probe_d_funct3 : FUNCT3_LW),
      .data_o(dmem_data_o)
  );

  // Memory stage - handles results from memory operations
  assign probe_m_pc = probe_e_pc;
  assign probe_m_address = probe_e_alu_res;
  assign probe_m_size_encoded = probe_d_funct3[1:0];
  
  // Show what data we got from memory
  assign probe_m_data = dmem_data_o;

  // Writeback stage - final step where results go back to registers
  assign probe_w_pc = probe_e_pc;
  assign probe_w_enable = regwren;
  assign probe_w_destination = probe_d_rd;
  
  // Writeback logic that decides what value to write back
  writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
  ) writeback_stage (
      .pc_i(probe_e_pc),
      .alu_res_i(probe_e_alu_res),
      .memory_data_i(dmem_data_o),
      .wbsel_i(wbsel),
      .brtaken_i(probe_e_br_taken),
      .writeback_data_o(probe_w_data),
      .next_pc_o(next_pc)
  );

  // Send the writeback result to the register file
  assign probe_r_write_data = probe_w_data;

  // Used to detect when the program should end
  assign data_out = d_insn;

  // program termination logic
  reg is_program = 0;
  always_ff @(posedge clk) begin
      if (data_out == 32'h00000073) $finish; // directly terminate if see ecall
      if (data_out == 32'h00008067) is_program = 1; // if see ret instruction, it is simple program test
      // [TODO] Change reg_file.registers[2] to the appropriate x2 register based on your module instantiations...
      if (is_program && (reg_file.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
  end

endmodule : pd5
