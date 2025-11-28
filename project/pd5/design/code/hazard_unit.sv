/*
 * Module: hazard_unit
 *
 * Description:
 *   This module keeps our pipeline running smoothly by detecting data hazards
 *   and deciding when we need to stall, flush, or forward data between stages.
 *   Think of it as the traffic controller for our processor pipeline.
 */

module hazard_unit (
    // -------------------------
    // ID stage inputs (instruction currently being decoded)
    // -------------------------
    input  logic [4:0] d_rs1,
    input  logic [4:0] d_rs2,
    input  logic [4:0] d_rd,           // ADD: destination reg of ID stage instruction
    input  logic       d_regwren,      // ADD: will ID stage write to a register?

    // -------------------------
    // EX stage inputs
    // -------------------------
    input  logic [4:0] e_rs1,
    input  logic [4:0] e_rs2,
    input  logic [4:0] e_rd,
    input  logic       e_memren,
    input  logic       e_regwren,

    // -------------------------
    // MEM stage inputs
    // -------------------------
    input  logic [4:0] m_rd,
    input  logic       m_regwren,

    // -------------------------
    // WB stage inputs
    // -------------------------
    input  logic [4:0] w_rd,
    input  logic       w_regwren,

    // -------------------------
    // Branch control
    // -------------------------
    input  logic       e_br_taken,

    // -------------------------
    // Pipeline control outputs
    // -------------------------
    output logic       stall_if,
    output logic       ifid_wren,
    output logic       ifid_flush,
    output logic       idex_flush,

    // -------------------------
    // Forwarding control outputs
    // -------------------------
    output logic [1:0] rs1_sel,
    output logic [1:0] rs2_sel
);

    // ===========================================================
    // Load-use hazard detection (EX stage load -> ID stage use)
    // Need to stall because data isn't available until after MEM
    // ===========================================================
    logic load_use_hazard;

    assign load_use_hazard =
        e_memren &&
        (e_rd != 5'd0) &&
        ((e_rd == d_rs1) || (e_rd == d_rs2));

    // ===========================================================
    // RAW hazard detection (EX stage ALU -> ID stage use)
    // Since RF writes on posedge and reads are combinational,
    // we need 1 stall cycle, then forward from MEM stage
    // ===========================================================
    // logic raw_hazard_ex;

    // assign raw_hazard_ex =
    //     e_regwren &&
    //     !e_memren &&  // Don't double-count load-use
    //     (e_rd != 5'd0) &&
    //     ((e_rd == d_rs1) || (e_rd == d_rs2));

    // ===========================================================
    // Combined stall signal - only load-use needs stall
    // (RF reads on negedge, so WB→ID forwarding happens automatically)
    // ===========================================================
    logic stall_hazard;
    assign stall_hazard = load_use_hazard;  // Remove raw_hazard_ex

    // ===========================================================
    // Pipeline control signals
    // ===========================================================
    
    // Stall IF when hazard detected (unless branch flushes everything)
    assign stall_if = stall_hazard && !e_br_taken;

    // Disable IF/ID write when stalling (keep same instruction in ID)
    assign ifid_wren = !stall_hazard | e_br_taken;

    // Flush IF/ID only on branch taken
    assign ifid_flush = e_br_taken;

    // Insert bubble into ID/EX on hazard or branch
    assign idex_flush = e_br_taken | stall_hazard;

    // ===========================================================
    // Forwarding logic (MEM and WB to EX)
    // ===========================================================
    always_comb begin
        rs1_sel = 2'b00;
        rs2_sel = 2'b00;

        // RS1 forwarding - MEM has priority over WB
        if (m_regwren && (m_rd != 5'd0) && (m_rd == e_rs1))
            rs1_sel = 2'b01;
        else if (w_regwren && (w_rd != 5'd0) && (w_rd == e_rs1))
            rs1_sel = 2'b10;

        // RS2 forwarding - MEM has priority over WB
        if (m_regwren && (m_rd != 5'd0) && (m_rd == e_rs2))
            rs2_sel = 2'b01;
        else if (w_regwren && (w_rd != 5'd0) && (w_rd == e_rs2))
            rs2_sel = 2'b10;
    end

endmodule : hazard_unit