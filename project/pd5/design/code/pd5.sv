/*
 * Module: pd5
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * In PD5 this module instantiates the 5-stage pipeline, including:
 *  - fetch and instruction memory
 *  - decode + control
 *  - register file
 *  - execute (ALU)
 *  - data memory
 *  - writeback
 *  - pipeline registers between each stage
 *  - hazard unit for stalls, flushes, and forwarding
 *  
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

`include "constants.svh"

module pd5 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

  /*
   * Probes
   */

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
  logic [DWIDTH-1:0] probe_d_imm;
  logic [4:0]        probe_d_shamt;

  // Register File Probes
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

  // --------------------------------------------------------------------
  // Internal datapath/control signals
  // --------------------------------------------------------------------

  // Instruction passing through decode (for control)
  logic [DWIDTH-1:0] d_insn;

  // Next PC computed for branch/jump targets (from EX-stage writeback)
  logic [AWIDTH-1:0] next_pc;

  // For program termination
  logic [DWIDTH-1:0] data_out;

  // Control outputs from decode/control (ID stage)
  logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
  logic [1:0] wbsel;
  logic [3:0] alusel;

  // Raw data from data memory
  logic [DWIDTH-1:0] dmem_data_o;

  // Raw outputs from the register file before forwarding
  logic [DWIDTH-1:0] rf_rs1data_raw;
  logic [DWIDTH-1:0] rf_rs2data_raw;

  // --------------------------------------------------------------------
  // Pipeline register signals (between stages)
  // --------------------------------------------------------------------

  // IF/ID outputs (to decode)
  logic [AWIDTH-1:0] ifid_pc;
  logic [DWIDTH-1:0] ifid_insn;

  // ID/EX outputs (EX stage inputs)
  logic [AWIDTH-1:0] e_pc;
  logic [DWIDTH-1:0] e_rs1data;
  logic [DWIDTH-1:0] e_rs2data;
  logic [DWIDTH-1:0] e_imm;
  logic [4:0]        e_rs1;
  logic [4:0]        e_rs2;
  logic [4:0]        e_rd;
  logic [2:0]        e_funct3;
  logic [6:0]        e_funct7;
  logic [6:0]        e_opcode;
  logic              e_regwren;
  logic              e_memren;
  logic              e_memwren;
  logic [1:0]        e_wbsel;
  logic [3:0]        e_alusel;
  logic              e_pcsel;            // Add this line

  // EX/MEM outputs (MEM stage inputs)
  logic [AWIDTH-1:0] m_pc;
  logic [DWIDTH-1:0] m_alu_res;
  logic [DWIDTH-1:0] m_rs2data;
  logic [4:0]        m_rd;
  logic [2:0]        m_funct3;
  logic              m_regwren;
  logic              m_memren;
  logic              m_memwren;
  logic [1:0]        m_wbsel;
  logic              m_br_taken;

  // MEM/WB outputs (WB stage inputs)
  logic [AWIDTH-1:0] w_pc;
  logic [DWIDTH-1:0] w_alu_res;
  logic [DWIDTH-1:0] w_mem_data;
  logic [4:0]        w_rd;
  logic              w_regwren;
  logic [1:0]        w_wbsel;
  logic              w_br_taken;

  // --------------------------------------------------------------------
  // Hazard unit outputs
  // --------------------------------------------------------------------
  logic       stall_if;
  logic       ifid_wren;
  logic       ifid_flush;
  logic       idex_flush;
  logic [1:0] rs1_sel;
  logic [1:0] rs2_sel;

  // Forwarded operands into the ALU (EX stage)
  logic [DWIDTH-1:0] e_rs1_val;
  logic [DWIDTH-1:0] e_rs2_val;

  // ALU outputs (EX stage)
  logic [DWIDTH-1:0] e_alu_res;
  logic              e_br_taken;

  // --------------------------------------------------------------------
  // Fetch stage – program counter update and instruction fetch
  // --------------------------------------------------------------------

  // PC selection into fetch:
  //   - When stall_if is asserted, hold the same PC value by feeding
  //     the current PC back as the target and forcing pcsel_i=1.
  //   - Otherwise, use the next_pc from the EX-stage writeback logic
  //     whenever control says so (e_pcsel) or a branch is taken.
  logic              fetch_pcsel;
  logic [AWIDTH-1:0] fetch_pctarget;

  assign fetch_pcsel   = stall_if ? 1'b1 : (e_pcsel || e_br_taken);
  assign fetch_pctarget = stall_if ? probe_f_pc : next_pc;

  fetch #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASEADDR(32'h01000000)
  ) fetch_stage (
      .clk(clk),
      .rst(reset),
      .pcsel_i(fetch_pcsel),
      .pctarget_i(fetch_pctarget),
      .pc_o(probe_f_pc),
      .insn_o() // instruction comes from imem below
  );

  // Instruction memory – combinational read of instruction at PC
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

  // --------------------------------------------------------------------
  // Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB
  // --------------------------------------------------------------------

  pipeline_registers #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH)
  ) pipe_regs (
      .clk(clk),
      .reset(reset),

      // IF/ID: Fetch -> Decode
      .ifid_wren (ifid_wren),
      .ifid_flush(ifid_flush),
      .f_pc      (probe_f_pc),
      .f_insn    (probe_f_insn),
      .d_pc      (ifid_pc),
      .d_insn    (ifid_insn),

      // ID/EX: Decode -> Execute
      .idex_wren (1'b1),        // we only bubble via idex_flush; no separate stall
      .idex_flush(idex_flush),

      .d_pc_i    (probe_d_pc),  // PC from decode stage
      .d_rs1data (rf_rs1data_raw),
      .d_rs2data (rf_rs2data_raw),
      .d_imm     (probe_d_imm),
      .d_rs1     (probe_d_rs1),
      .d_rs2     (probe_d_rs2),
      .d_rd      (probe_d_rd),
      .d_funct3  (probe_d_funct3),
      .d_funct7  (probe_d_funct7),
      .d_opcode  (probe_d_opcode),

      .d_regwren (regwren),
      .d_memren  (memren),
      .d_memwren (memwren),
      .d_wbsel   (wbsel),
      .d_alusel  (alusel),
      .d_pcsel   (pcsel),             // Add this connection

      .e_pc      (e_pc),
      .e_rs1data (e_rs1data),
      .e_rs2data (e_rs2data),
      .e_imm     (e_imm),
      .e_rs1     (e_rs1),
      .e_rs2     (e_rs2),
      .e_rd      (e_rd),
      .e_funct3  (e_funct3),
      .e_funct7  (e_funct7),
      .e_opcode  (e_opcode),
      .e_regwren (e_regwren),
      .e_memren  (e_memren),
      .e_memwren (e_memwren),
      .e_wbsel   (e_wbsel),
      .e_alusel  (e_alusel),
      .e_pcsel   (e_pcsel),           // Add this connection

      // EX/MEM: Execute -> Memory
      .exmem_wren (1'b1),

      .e_pc_i     (e_pc),
      .e_alu_res  (e_alu_res),
      .e_rs2data_i(e_rs2_val), // already forwarded value for stores
      .e_rd_i     (e_rd),
      .e_funct3_i (e_funct3),

      .e_regwren_i(e_regwren),
      .e_memren_i (e_memren),
      .e_memwren_i(e_memwren),
      .e_wbsel_i  (e_wbsel),
      .e_br_taken (e_br_taken),

      .m_pc       (m_pc),
      .m_alu_res  (m_alu_res),
      .m_rs2data  (m_rs2data),
      .m_rd       (m_rd),
      .m_funct3   (m_funct3),
      .m_regwren  (m_regwren),
      .m_memren   (m_memren),
      .m_memwren  (m_memwren),
      .m_wbsel    (m_wbsel),
      .m_br_taken (m_br_taken),

      // MEM/WB: Memory -> Writeback
      .memwb_wren (1'b1),

      .m_pc_i      (m_pc),
      .m_alu_res_i (m_alu_res),
      .m_mem_data  (dmem_data_o),
      .m_rd_i      (m_rd),

      .m_regwren_i (m_regwren),
      .m_wbsel_i   (m_wbsel),
      .m_br_taken_i(m_br_taken),

      .w_pc       (w_pc),
      .w_alu_res  (w_alu_res),
      .w_mem_data (w_mem_data),
      .w_rd       (w_rd),
      .w_regwren  (w_regwren),
      .w_wbsel    (w_wbsel),
      .w_br_taken (w_br_taken)
  );

  // --------------------------------------------------------------------
  // Decode stage – runs on instruction/PC coming from IF/ID
  // --------------------------------------------------------------------

  decode #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH)
  ) decode_stage (
      .clk   (clk),
      .rst   (reset),
      .insn_i(ifid_insn),
      .pc_i  (ifid_pc),

      .pc_o     (probe_d_pc),
      .insn_o   (d_insn),
      .opcode_o (probe_d_opcode),
      .rd_o     (probe_d_rd),
      .rs1_o    (probe_d_rs1),
      .rs2_o    (probe_d_rs2),
      .funct7_o (probe_d_funct7),
      .funct3_o (probe_d_funct3),
      .shamt_o  (probe_d_shamt),
      .imm_o    (probe_d_imm)
  );

  // --------------------------------------------------------------------
  // Control unit – generates control signals from current ID instruction
  // --------------------------------------------------------------------

  control #(
      .DWIDTH(DWIDTH)
  ) control_unit (
      .insn_i   (d_insn),
      .opcode_i (probe_d_opcode),
      .funct7_i (probe_d_funct7),
      .funct3_i (probe_d_funct3),
      .pcsel_o  (pcsel),
      .immsel_o (immsel),
      .regwren_o(regwren),
      .rs1sel_o (rs1sel),
      .rs2sel_o (rs2sel),
      .memren_o (memren),
      .memwren_o(memwren),
      .wbsel_o  (wbsel),
      .alusel_o (alusel)
  );

  // --------------------------------------------------------------------
  // Register file – read in ID, write in WB
  // --------------------------------------------------------------------

  // Read addresses come from current decode-stage instruction
  assign probe_r_read_rs1 = probe_d_rs1;
  assign probe_r_read_rs2 = probe_d_rs2;

  // Writeback controls come from MEM/WB stage
  assign probe_r_write_enable      = w_regwren;
  assign probe_r_write_destination = w_rd;

  register_file #(
      .DWIDTH(DWIDTH)
  ) reg_file (
      .clk       (clk),
      .rst       (reset),
      .rs1_i     (probe_r_read_rs1),
      .rs2_i     (probe_r_read_rs2),
      .rd_i      (probe_r_write_destination),
      .datawb_i  (probe_w_data),
      .regwren_i (probe_r_write_enable),
      .rs1data_o (rf_rs1data_raw),
      .rs2data_o (rf_rs2data_raw)
  );

  // Expose raw register-file reads on probes
  assign probe_r_read_rs1_data = rf_rs1data_raw;
  assign probe_r_read_rs2_data = rf_rs2data_raw;

  // --------------------------------------------------------------------
  // Hazard unit – stalls, flushes, and forwarding control
  // --------------------------------------------------------------------

  hazard_unit hazards (
      // ID stage
      .d_rs1     (probe_d_rs1),
      .d_rs2     (probe_d_rs2),

      // EX stage (from ID/EX pipeline)
      .e_rs1     (e_rs1),
      .e_rs2     (e_rs2),
      .e_rd      (e_rd),
      .e_memren  (e_memren),
      .e_regwren (e_regwren),    // ADD THIS LINE

      // MEM stage (from EX/MEM pipeline)
      .m_rd      (m_rd),
      .m_regwren (m_regwren),

      // WB stage (from MEM/WB pipeline)
      .w_rd      (w_rd),
      .w_regwren (w_regwren),

      // Branch taken from EX stage
      .e_br_taken(e_br_taken),

      // Pipeline control outputs
      .stall_if  (stall_if),
      .ifid_wren (ifid_wren),
      .ifid_flush(ifid_flush),
      .idex_flush(idex_flush),

      // Forwarding select outputs
      .rs1_sel   (rs1_sel),
      .rs2_sel   (rs2_sel)
  );

  // --------------------------------------------------------------------
  // Execute stage – ALU + forwarding muxes
  // --------------------------------------------------------------------

  // EX-stage PC probe
  assign probe_e_pc = e_pc;

  // Forwarding muxes for ALU operands
  always_comb begin
      // Default: use values from ID/EX pipeline
      e_rs1_val = e_rs1data;
      e_rs2_val = e_rs2data;

      // rs1 forwarding
      case (rs1_sel)
          2'b01: e_rs1_val = m_alu_res;    // from MEM (EX/MEM)
          2'b10: e_rs1_val = probe_w_data; // from WB (MEM/WB)
          default: /* 2'b00 or 2'b11 */ ;
      endcase

      // rs2 forwarding
      case (rs2_sel)
          2'b01: e_rs2_val = m_alu_res;    // from MEM (EX/MEM)
          2'b10: e_rs2_val = probe_w_data; // from WB (MEM/WB)
          default: /* 2'b00 or 2'b11 */ ;
      endcase
  end

  alu #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
  ) alu_stage (
      .pc_i    (e_pc),
      .rs1_i   (e_rs1_val),
      .rs2_i   (e_rs2_val),
      .imm_i   (e_imm),
      .opcode_i(e_opcode),
      .funct3_i(e_funct3),
      .funct7_i(e_funct7),
      .res_o   (e_alu_res),
      .brtaken_o(e_br_taken)
  );

  // Probes for execute stage results
  assign probe_e_alu_res  = e_alu_res;
  assign probe_e_br_taken = e_br_taken;

  // --------------------------------------------------------------------
  // EX-stage writeback (for PC update only)
  // --------------------------------------------------------------------

  // This instance only computes next_pc for branch/jump targets.
  // The register-file writeback path uses the MEM/WB instance below.
  writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
  ) writeback_pc (
      .pc_i          (probe_e_pc),
      .alu_res_i     (e_alu_res),
      .memory_data_i (dmem_data_o), // not used for PC update in branch/jump
      .wbsel_i       (e_wbsel),
      .brtaken_i     (e_br_taken),
      .writeback_data_o(),          // unused here
      .next_pc_o     (next_pc)
  );

  // --------------------------------------------------------------------
  // Memory stage – data memory access
  // --------------------------------------------------------------------

  memory #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH),
      .BASE_ADDR(32'h01000000)
  ) dmem (
      .clk       (clk),
      .rst       (reset),
      .addr_i    (m_alu_res),
      .data_i    (m_rs2data),
      .read_en_i (m_memren),
      .write_en_i(m_memwren),
      .funct3_i  (m_funct3),
      .data_o    (dmem_data_o)
  );

  // Memory stage probes
  assign probe_m_pc           = m_pc;
  assign probe_m_address      = m_alu_res;
  assign probe_m_size_encoded = m_funct3[1:0];
  assign probe_m_data         = m_rs2data;

  // --------------------------------------------------------------------
  // Writeback stage – final selection of data to write to registers
  // --------------------------------------------------------------------

  // Use MEM/WB-stage values for architecturally visible writeback
  writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
  ) writeback_stage (
      .pc_i          (w_pc),
      .alu_res_i     (w_alu_res),
      .memory_data_i (w_mem_data),
      .wbsel_i       (w_wbsel),
      .brtaken_i     (w_br_taken),
      .writeback_data_o(probe_w_data),
      .next_pc_o     () // not used – PC is handled by writeback_pc
  );

  // Writeback probes
  assign probe_w_pc          = w_pc;
  assign probe_w_enable      = w_regwren;
  assign probe_w_destination = w_rd;
  // probe_w_data is already driven by writeback_stage

  // --------------------------------------------------------------------
  // Program termination logic
  // --------------------------------------------------------------------

  // Used to detect when the program should end
  assign data_out = d_insn;

  reg is_program = 0;
  always_ff @(posedge clk) begin
      if (data_out == 32'h00000073) $finish; // directly terminate if see ecall
      if (data_out == 32'h00008067) is_program = 1; // if see ret instruction, it is simple program test
      // [TODO] Change reg_file.registers[2] to the appropriate x2 register based on your module instantiations...
      if (is_program && (reg_file.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
  end

endmodule : pd5