/*
 * Module: pipeline_registers
 *
 * Description:
 *   Contains all pipeline registers for a 5-stage RISC-V pipeline:
 *   - Instruction Fetch to Instruction Decode (IF/ID)
 *   - Instruction Decode to Execute (ID/EX)
 *   - Execute to Memory (EX/MEM)
 *   - Memory to Writeback (MEM/WB)
 *
 *   - IF/ID and ID/EX stages support flushing to handle branch mispredictions
 *     and hazard bubbles.
 *   - All stages support stalling through write enable signals.
 *
 *   This module should be connected to decode, control, register file, execute,
 *   memory, and writeback modules in your top-level design.
 */

module pipeline_registers #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input  logic clk,
    input  logic reset,

    // ================================================================
    // IF/ID: Instruction Fetch to Decode stage register
    // ================================================================
    input  logic               ifid_wren,          // Write enable for IF/ID register
    input  logic               ifid_flush,         // Clear stage and insert NOP
    input  logic [AWIDTH-1:0]  f_pc,               // Program counter from fetch
    input  logic [DWIDTH-1:0]  f_insn,             // Instruction from fetch

    output logic [AWIDTH-1:0]  d_pc,               // Program counter to decode
    output logic [DWIDTH-1:0]  d_insn,             // Instruction to decode

    // ================================================================
    // ID/EX: Decode to Execute stage register
    // ================================================================
    input  logic               idex_wren,          // Write enable for ID/EX register
    input  logic               idex_flush,         // Insert bubble into execute

    input  logic [AWIDTH-1:0]  d_pc_i,             // Program counter from decode
    input  logic [DWIDTH-1:0]  d_rs1data,          // Source register 1 data
    input  logic [DWIDTH-1:0]  d_rs2data,          // Source register 2 data
    input  logic [DWIDTH-1:0]  d_imm,              // Immediate value
    input  logic [4:0]         d_rs1,              // Source register 1 address
    input  logic [4:0]         d_rs2,              // Source register 2 address
    input  logic [4:0]         d_rd,               // Destination register address
    input  logic [2:0]         d_funct3,           // Function 3 field
    input  logic [6:0]         d_funct7,           // Function 7 field
    input  logic [6:0]         d_opcode,           // Opcode field

    input  logic               d_regwren,          // Register write enable
    input  logic               d_memren,           // Memory read enable
    input  logic               d_memwren,          // Memory write enable
    input  logic [1:0]         d_wbsel,            // Writeback select
    input  logic [3:0]         d_alusel,           // ALU operation select

    output logic [AWIDTH-1:0]  e_pc,               // Program counter to execute
    output logic [DWIDTH-1:0]  e_rs1data,          // Source register 1 data
    output logic [DWIDTH-1:0]  e_rs2data,          // Source register 2 data
    output logic [DWIDTH-1:0]  e_imm,              // Immediate value
    output logic [4:0]         e_rs1,              // Source register 1 address
    output logic [4:0]         e_rs2,              // Source register 2 address
    output logic [4:0]         e_rd,               // Destination register address
    output logic [2:0]         e_funct3,           // Function 3 field
    output logic [6:0]         e_funct7,           // Function 7 field
    output logic [6:0]         e_opcode,           // Opcode field

    output logic               e_regwren,          // Register write enable
    output logic               e_memren,           // Memory read enable
    output logic               e_memwren,          // Memory write enable
    output logic [1:0]         e_wbsel,            // Writeback select
    output logic [3:0]         e_alusel,           // ALU operation select

    // ================================================================
    // EX/MEM: Execute to Memory stage register
    // ================================================================
    input  logic               exmem_wren,         // Write enable for EX/MEM register

    input  logic [AWIDTH-1:0]  e_pc_i,             // Program counter from execute
    input  logic [DWIDTH-1:0]  e_alu_res,          // ALU result
    input  logic [DWIDTH-1:0]  e_rs2data_i,        // Data for store operations
    input  logic [4:0]         e_rd_i,             // Destination register address
    input  logic [2:0]         e_funct3_i,         // Function 3 field

    input  logic               e_regwren_i,        // Register write enable
    input  logic               e_memren_i,         // Memory read enable
    input  logic               e_memwren_i,        // Memory write enable
    input  logic [1:0]         e_wbsel_i,          // Writeback select
    input  logic               e_br_taken,         // Branch taken signal
    input  logic [4:0]         e_rs2_i,            // Source register 2 address for store forwarding

    output logic [AWIDTH-1:0]  m_pc,               // Program counter to memory
    output logic [DWIDTH-1:0]  m_alu_res,          // ALU result
    output logic [DWIDTH-1:0]  m_rs2data,          // Data for store operations
    output logic [4:0]         m_rd,               // Destination register address
    output logic [2:0]         m_funct3,           // Function 3 field

    output logic               m_regwren,          // Register write enable
    output logic               m_memren,           // Memory read enable
    output logic               m_memwren,          // Memory write enable
    output logic [1:0]         m_wbsel,            // Writeback select
    output logic               m_br_taken,         // Branch taken signal
    output logic [4:0]         m_rs2,              // Source register 2 address for store forwarding

    // ================================================================
    // MEM/WB: Memory to Writeback stage register
    // ================================================================
    input  logic               memwb_wren,         // Write enable for MEM/WB register

    input  logic [AWIDTH-1:0]  m_pc_i,             // Program counter from memory
    input  logic [DWIDTH-1:0]  m_alu_res_i,        // ALU result
    input  logic [DWIDTH-1:0]  m_mem_data,         // Data from memory
    input  logic [4:0]         m_rd_i,             // Destination register address

    input  logic               m_regwren_i,        // Register write enable
    input  logic [1:0]         m_wbsel_i,          // Writeback select
    input  logic               m_br_taken_i,       // Branch taken signal

    output logic [AWIDTH-1:0]  w_pc,               // Program counter to writeback
    output logic [DWIDTH-1:0]  w_alu_res,          // ALU result
    output logic [DWIDTH-1:0]  w_mem_data,         // Data from memory
    output logic [4:0]         w_rd,               // Destination register address

    output logic               w_regwren,          // Register write enable
    output logic [1:0]         w_wbsel,            // Writeback select
    output logic               w_br_taken          // Branch taken signal
);

    // ================================================================
    // IF/ID: Fetch to Decode stage storage
    // ================================================================
    logic [AWIDTH-1:0] ifid_pc_reg;                // Program counter register
    logic [DWIDTH-1:0] ifid_insn_reg;              // Instruction register

    // Reset or flush logic for Fetch/Decode stage
    always_ff @(posedge clk) begin
        if (reset) begin
            ifid_pc_reg   <= '0;
            ifid_insn_reg <= 32'h00000000;
        end else if (ifid_flush) begin
            ifid_pc_reg   <= '0;
            ifid_insn_reg <= 32'h00000000;
        end else if (ifid_wren) begin
            ifid_pc_reg   <= f_pc;
            ifid_insn_reg <= f_insn;
        end
    end

    assign d_pc   = ifid_pc_reg;
    assign d_insn = ifid_insn_reg;

    // ================================================================
    // ID/EX: Decode to Execute stage storage
    // ================================================================
    logic [AWIDTH-1:0] idex_pc_reg;                // Program counter register
    logic [DWIDTH-1:0] idex_rs1data_reg;           // Source register 1 data
    logic [DWIDTH-1:0] idex_rs2data_reg;           // Source register 2 data
    logic [DWIDTH-1:0] idex_imm_reg;               // Immediate value
    logic [4:0]        idex_rs1_reg;               // Source register 1 address
    logic [4:0]        idex_rs2_reg;               // Source register 2 address
    logic [4:0]        idex_rd_reg;                // Destination register address
    logic [2:0]        idex_funct3_reg;            // Function 3 field
    logic [6:0]        idex_funct7_reg;            // Function 7 field
    logic [6:0]        idex_opcode_reg;            // Opcode field

    logic              idex_regwren_reg;           // Register write enable
    logic              idex_memren_reg;            // Memory read enable
    logic              idex_memwren_reg;           // Memory write enable
    logic [1:0]        idex_wbsel_reg;             // Writeback select
    logic [3:0]        idex_alusel_reg;            // ALU operation select

    always_ff @(posedge clk) begin
        if (reset) begin
            idex_pc_reg       <= '0;
            idex_rs1data_reg  <= '0;
            idex_rs2data_reg  <= '0;
            idex_imm_reg      <= '0;
            idex_rs1_reg      <= '0;
            idex_rs2_reg      <= '0;
            idex_rd_reg       <= '0;
            idex_funct3_reg   <= '0;
            idex_funct7_reg   <= '0;
            idex_opcode_reg   <= '0;
            idex_regwren_reg  <= 1'b0;
            idex_memren_reg   <= 1'b0;
            idex_memwren_reg  <= 1'b0;
            idex_wbsel_reg    <= 2'b00;
            idex_alusel_reg   <= 4'b0000;
        end else if (idex_flush) begin
            // Insert bubble: clear all control signals and data
            idex_pc_reg       <= '0;
            idex_rs1data_reg  <= '0;
            idex_rs2data_reg  <= '0;
            idex_imm_reg      <= '0;
            idex_rs1_reg      <= '0;
            idex_rs2_reg      <= '0;
            idex_rd_reg       <= '0;
            idex_funct3_reg   <= '0;
            idex_funct7_reg   <= '0;
            idex_opcode_reg   <= '0;
            idex_regwren_reg  <= 1'b0;
            idex_memren_reg   <= 1'b0;
            idex_memwren_reg  <= 1'b0;
            idex_wbsel_reg    <= 2'b00;
            idex_alusel_reg   <= 4'b0000;
        end else if (idex_wren) begin
            idex_pc_reg       <= d_pc_i;
            idex_rs1data_reg  <= d_rs1data;
            idex_rs2data_reg  <= d_rs2data;
            idex_imm_reg      <= d_imm;
            idex_rs1_reg      <= d_rs1;
            idex_rs2_reg      <= d_rs2;
            idex_rd_reg       <= d_rd;
            idex_funct3_reg   <= d_funct3;
            idex_funct7_reg   <= d_funct7;
            idex_opcode_reg   <= d_opcode;
            idex_regwren_reg  <= d_regwren;
            idex_memren_reg   <= d_memren;
            idex_memwren_reg  <= d_memwren;
            idex_wbsel_reg    <= d_wbsel;
            idex_alusel_reg   <= d_alusel;
        end
    end

    assign e_pc       = idex_pc_reg;
    assign e_rs1data  = idex_rs1data_reg;
    assign e_rs2data  = idex_rs2data_reg;
    assign e_imm      = idex_imm_reg;
    assign e_rs1      = idex_rs1_reg;
    assign e_rs2      = idex_rs2_reg;
    assign e_rd       = idex_rd_reg;
    assign e_funct3   = idex_funct3_reg;
    assign e_funct7   = idex_funct7_reg;
    assign e_opcode   = idex_opcode_reg;
    assign e_regwren  = idex_regwren_reg;
    assign e_memren   = idex_memren_reg;
    assign e_memwren  = idex_memwren_reg;
    assign e_wbsel    = idex_wbsel_reg;
    assign e_alusel   = idex_alusel_reg;

    // ================================================================
    // EX/MEM: Execute to Memory stage storage
    // ================================================================
    logic [AWIDTH-1:0] exmem_pc_reg;               // Program counter register
    logic [DWIDTH-1:0] exmem_alu_res_reg;          // ALU result
    logic [DWIDTH-1:0] exmem_rs2data_reg;          // Source register 2 data for stores
    logic [4:0]        exmem_rd_reg;               // Destination register address
    logic [2:0]        exmem_funct3_reg;           // Function 3 field

    logic              exmem_regwren_reg;          // Register write enable
    logic              exmem_memren_reg;           // Memory read enable
    logic              exmem_memwren_reg;          // Memory write enable
    logic [1:0]        exmem_wbsel_reg;            // Writeback select
    logic              exmem_br_taken_reg;         // Branch taken signal
    logic [4:0]        exmem_rs2_reg;              // Source register 2 address

    always_ff @(posedge clk) begin
        if (reset) begin
            exmem_pc_reg       <= '0;
            exmem_alu_res_reg  <= '0;
            exmem_rs2data_reg  <= '0;
            exmem_rd_reg       <= '0;
            exmem_funct3_reg   <= '0;
            exmem_regwren_reg  <= 1'b0;
            exmem_memren_reg   <= 1'b0;
            exmem_memwren_reg  <= 1'b0;
            exmem_wbsel_reg    <= 2'b00;
            exmem_br_taken_reg <= 1'b0;
            exmem_rs2_reg      <= '0;  // in reset
        end else if (exmem_wren) begin
            exmem_pc_reg       <= e_pc_i;
            exmem_alu_res_reg  <= e_alu_res;
            exmem_rs2data_reg  <= e_rs2data_i;
            exmem_rd_reg       <= e_rd_i;
            exmem_funct3_reg   <= e_funct3_i;
            exmem_regwren_reg  <= e_regwren_i;
            exmem_memren_reg   <= e_memren_i;
            exmem_memwren_reg  <= e_memwren_i;
            exmem_wbsel_reg    <= e_wbsel_i;
            exmem_br_taken_reg <= e_br_taken;
            exmem_rs2_reg      <= e_rs2_i;  // in write enable
        end
    end

    assign m_pc       = exmem_pc_reg;
    assign m_alu_res  = exmem_alu_res_reg;
    assign m_rs2data  = exmem_rs2data_reg;
    assign m_rd       = exmem_rd_reg;
    assign m_funct3   = exmem_funct3_reg;
    assign m_regwren  = exmem_regwren_reg;
    assign m_memren   = exmem_memren_reg;
    assign m_memwren  = exmem_memwren_reg;
    assign m_wbsel    = exmem_wbsel_reg;
    assign m_br_taken = exmem_br_taken_reg;
    assign m_rs2      = exmem_rs2_reg;

    // ================================================================
    // MEM/WB: Memory to Writeback stage storage
    // ================================================================
    logic [AWIDTH-1:0] memwb_pc_reg;               // Program counter register
    logic [DWIDTH-1:0] memwb_alu_res_reg;          // ALU result
    logic [DWIDTH-1:0] memwb_mem_data_reg;         // Memory data
    logic [4:0]        memwb_rd_reg;               // Destination register address

    logic              memwb_regwren_reg;          // Register write enable
    logic [1:0]        memwb_wbsel_reg;            // Writeback select
    logic              memwb_br_taken_reg;         // Branch taken signal

    always_ff @(posedge clk) begin
        if (reset) begin
            memwb_pc_reg       <= '0;
            memwb_alu_res_reg  <= '0;
            memwb_mem_data_reg <= '0;
            memwb_rd_reg       <= '0;
            memwb_regwren_reg  <= 1'b0;
            memwb_wbsel_reg    <= 2'b00;
            memwb_br_taken_reg <= 1'b0;
        end else if (memwb_wren) begin
            memwb_pc_reg       <= m_pc_i;
            memwb_alu_res_reg  <= m_alu_res_i;
            memwb_mem_data_reg <= m_mem_data;
            memwb_rd_reg       <= m_rd_i;
            memwb_regwren_reg  <= m_regwren_i;
            memwb_wbsel_reg    <= m_wbsel_i;
            memwb_br_taken_reg <= m_br_taken_i;
        end
    end

    assign w_pc       = memwb_pc_reg;
    assign w_alu_res  = memwb_alu_res_reg;
    assign w_mem_data = memwb_mem_data_reg;
    assign w_rd       = memwb_rd_reg;
    assign w_regwren  = memwb_regwren_reg;
    assign w_wbsel    = memwb_wbsel_reg;
    assign w_br_taken = memwb_br_taken_reg;

endmodule : pipeline_registers