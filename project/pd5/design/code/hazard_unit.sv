/*
 * Module: hazard_unit
 *
 * Description:
 *   This module keeps our pipeline running smoothly by detecting data hazards
 *   and deciding when we need to stall, flush, or forward data between stages.
 *   Think of it as the traffic controller for our processor pipeline.
 *
 * What it does:
 *   - Spots load-use hazards (when we need data that's still being fetched from memory)
 *   - Generates the necessary stall, bubble, and flush signals to handle hazards
 *   - Sets up forwarding paths so the ALU gets the freshest data available
 *   - Handles MEM-stage forwarding for store instructions
 *
 * A note on register x0:
 *   We ignore writes to x0 since it's hardwired to zero in RISC-V - no hazards there!
 *
 * How forwarding works (the rs?_sel outputs):
 *   2'b00 : No forwarding needed - just use what's in the ID/EX register
 *   2'b01 : Grab the value from MEM stage (it's newer!)
 *   2'b10 : Grab the value from WB stage (still newer than what we have)
 *   2'b11 : Not used (reserved for future needs)
 */

module hazard_unit #(
    parameter int DWIDTH = 32
)(
    // -------------------------
    // ID stage inputs
    // These tell us which registers the instruction in decode needs
    // -------------------------
    input  logic [4:0] d_rs1,
    input  logic [4:0] d_rs2,

    // -------------------------
    // EX stage inputs
    // We need to know:
    //   - Which registers this instruction is using (for forwarding)
    //   - Which register it will write to (for hazard detection)
    //   - Whether it's a load instruction (load-use hazard alert!)
    // -------------------------
    input  logic [4:0] e_rs1,
    input  logic [4:0] e_rs2,
    input  logic [4:0] e_rd,
    input  logic       e_memren,   // is this a load instruction?

    // -------------------------
    // MEM stage inputs
    // Used to forward results that just came out of the ALU
    // -------------------------
    input  logic [4:0]         m_rd,
    input  logic               m_regwren,
    input  logic [4:0]         m_rs2,              // Source register for store data
    input  logic               m_memwren,          // Is MEM stage doing a store?
    input  logic [DWIDTH-1:0]  m_alu_res,          // ALU result from MEM stage
    input  logic [DWIDTH-1:0]  m_rs2data,          // Store data from MEM stage

    // -------------------------
    // WB stage inputs
    // Used to forward results that are about to be written back
    // -------------------------
    input  logic [4:0]         w_rd,
    input  logic               w_regwren,
    input  logic [DWIDTH-1:0]  w_data,             // Writeback data

    // -------------------------
    // EX stage data inputs for forwarding muxes
    // -------------------------
    input  logic [DWIDTH-1:0]  e_rs1data,          // RS1 data from ID/EX
    input  logic [DWIDTH-1:0]  e_rs2data,          // RS2 data from ID/EX

    // -------------------------
    // Branch control
    // When a branch is taken, we need to flush the wrong-path instructions
    // -------------------------
    input  logic       e_br_taken,

    // -------------------------
    // Pipeline control outputs
    // These signals tell other pipeline stages what to do
    // -------------------------
    output logic       stall_if,       // tell IF stage to hold the PC
    output logic       ifid_wren,      // allow IF/ID register to update
    output logic       ifid_flush,     // turn IF/ID stage into a NOP
    output logic       idex_flush,     // turn ID/EX stage into a bubble

    // -------------------------
    // Forwarding control outputs
    // These tell the EX stage where to get its operands from
    // -------------------------
    output logic [1:0] rs1_sel,        // where should rs1 come from?
    output logic [1:0] rs2_sel,        // where should rs2 come from?

    // -------------------------
    // Forwarded data outputs
    // These are the actual forwarded values for EX and MEM stages
    // -------------------------
    output logic [DWIDTH-1:0] e_rs1_fwd,           // Forwarded RS1 for EX stage
    output logic [DWIDTH-1:0] e_rs2_fwd,           // Forwarded RS2 for EX stage
    output logic [DWIDTH-1:0] m_store_data_fwd     // Forwarded store data for MEM stage
);

    // ===========================================================
    // Detecting the dreaded load-use hazard
    //
    // This happens when:
    //  - The instruction in EX stage is loading from memory
    //  - It's going to write to a register (not x0)
    //  - The very next instruction in ID needs that same register
    //
    // We can't forward here because the data hasn't arrived from
    // memory yet! The only solution is to stall and wait.
    // ===========================================================
    logic load_use_hazard;

    assign load_use_hazard =
        e_memren &&
        (e_rd != 5'd0) &&
        ( (e_rd == d_rs1) || (e_rd == d_rs2) );

    // ===========================================================
    // Pipeline control: when to stall, when to flush
    //
    // Load-use hazard response:
    //   - Freeze the PC (stall_if) so we don't fetch a new instruction
    //   - Keep IF/ID register unchanged (disable write)
    //   - Insert a bubble in ID/EX (flush it to NOPs)
    //
    // Branch taken response:
    //   - Don't stall - we need to start fetching from the new target
    //   - Flush IF/ID (that instruction was on the wrong path)
    //   - Flush ID/EX (that one too - already in the pipeline)
    //
    // If both happen at once (unusual but possible), the branch flush
    // takes priority, but we OR the signals to be safe.
    // ===========================================================

    // Only stall when we hit a load-use hazard
    assign stall_if       = load_use_hazard;

    // Let IF/ID update unless we're stalling for a load-use hazard
    assign ifid_wren      = ~load_use_hazard;

    // Flush IF/ID only when a branch changes our path
    assign ifid_flush     = e_br_taken;

    // Insert bubble into ID/EX when we hit either hazard type
    assign idex_flush     = e_br_taken | load_use_hazard;

    // ===========================================================
    // Forwarding logic: getting the freshest data to the ALU
    //
    // For each source register the EX stage needs, we check if
    // a newer value is available further down the pipeline.
    //
    // Priority order (most recent first):
    //   1. MEM stage (just computed)     -> select 01
    //   2. WB stage  (about to write)    -> select 10
    //   3. ID/EX reg (what we already have) -> select 00
    //
    // We check MEM first because it's the most recent result.
    // ===========================================================
    always_comb begin
        // Start by assuming no forwarding is needed
        rs1_sel = 2'b00;
        rs2_sel = 2'b00;

        // ---------- Forwarding for rs1 ----------
        // First priority: check if MEM stage has what we need
        if (m_regwren &&
            (m_rd != 5'd0) &&
            (m_rd == e_rs1)) begin
            rs1_sel = 2'b01;   // forward from MEM stage
        end
        // Second priority: check WB stage
        else if (w_regwren &&
                 (w_rd != 5'd0) &&
                 (w_rd == e_rs1)) begin
            rs1_sel = 2'b10;   // forward from WB stage
        end

        // ---------- Forwarding for rs2 ----------
        // Same deal - check MEM first, then WB
        if (m_regwren &&
            (m_rd != 5'd0) &&
            (m_rd == e_rs2)) begin
            rs2_sel = 2'b01;   // forward from MEM stage
        end
        else if (w_regwren &&
                 (w_rd != 5'd0) &&
                 (w_rd == e_rs2)) begin
            rs2_sel = 2'b10;   // forward from WB stage
        end
    end

    // ===========================================================
    // EX stage forwarding muxes
    // Select the appropriate data source based on rs1_sel/rs2_sel
    // ===========================================================
    always_comb begin
        // RS1 forwarding mux
        case (rs1_sel)
            2'b01:   e_rs1_fwd = m_alu_res;    // Forward from MEM stage
            2'b10:   e_rs1_fwd = w_data;       // Forward from WB stage
            default: e_rs1_fwd = e_rs1data;   // No forwarding - use ID/EX value
        endcase

        // RS2 forwarding mux
        case (rs2_sel)
            2'b01:   e_rs2_fwd = m_alu_res;    // Forward from MEM stage
            2'b10:   e_rs2_fwd = w_data;       // Forward from WB stage
            default: e_rs2_fwd = e_rs2data;   // No forwarding - use ID/EX value
        endcase
    end

    // ===========================================================
    // MEM stage store data forwarding
    //
    // When a store instruction is in MEM stage and needs data from
    // an instruction that's currently in WB stage, we must forward
    // the WB result to the memory write data path.
    //
    // This handles sequences like:
    //   ADD x5, x1, x2    ; Result in WB stage
    //   SW  x5, 0(x10)    ; Store in MEM stage needs x5
    // ===========================================================
    always_comb begin
        m_store_data_fwd = m_rs2data;  // Default: use pipelined value

        // Forward from WB if the store's source register matches WB's destination
        if (m_memwren &&
            w_regwren &&
            (w_rd != 5'd0) &&
            (w_rd == m_rs2)) begin
            m_store_data_fwd = w_data;
        end
    end

endmodule : hazard_unit