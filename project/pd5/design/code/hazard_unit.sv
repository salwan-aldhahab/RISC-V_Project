module hazard_unit (

    // -------------------------
    // ID stage inputs
    // -------------------------
    input  logic [4:0] d_rs1,
    input  logic [4:0] d_rs2,

    // -------------------------
    // EX stage inputs
    // -------------------------
    input  logic [4:0] e_rs1,
    input  logic [4:0] e_rs2,
    input  logic [4:0] e_rd,
    input  logic       e_memren,

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
    // Branch / jump control
    // -------------------------
    input  logic       e_br_taken,
    input  logic [6:0] e_opcode,

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
    output logic [1:0] rs2_sel,

    // -------------------------
    // WM forwarding output
    // -------------------------
    output logic       wm_fwd_sel
);

    // ===========================================================
    // Load-use hazard detection
    // ===========================================================
    logic load_use_hazard;

    assign load_use_hazard =
        e_memren &&
        (e_rd != 5'd0) &&
        ((e_rd == d_rs1) || (e_rd == d_rs2));

    // ===========================================================
    // WB-to-Decode hazard detection
    // ===========================================================
    logic wd_hazard;

    assign wd_hazard =
        w_regwren &&
        (w_rd != 5'd0) &&
        ((w_rd == d_rs1) || (w_rd == d_rs2));

    // Combined stall signal
    logic stall_hazard;
    assign stall_hazard = load_use_hazard | wd_hazard;

    // ===========================================================
    // Jump detection
    // ===========================================================
    logic is_jump;

    assign is_jump =
        (e_opcode == 7'b1101111) ||   // JAL
        (e_opcode == 7'b1100111);     // JALR

    logic control_flow_change;
    assign control_flow_change = e_br_taken | is_jump;

    // ===========================================================
    // Pipeline control
    // ===========================================================
    assign stall_if   = stall_hazard;
    assign ifid_wren  = ~stall_hazard;

    // Flush only if not stalling
    assign ifid_flush = control_flow_change & ~stall_hazard;

    // Bubble on hazard or control flow change
    assign idex_flush = control_flow_change | stall_hazard;

    // ===========================================================
    // Forwarding logic (EX stage)
    // ===========================================================
    always_comb begin
        rs1_sel = 2'b00;
        rs2_sel = 2'b00;

        // rs1 forwarding
        if (m_regwren && (m_rd != 0) && (m_rd == e_rs1))
            rs1_sel = 2'b01;
        else if (w_regwren && (w_rd != 0) && (w_rd == e_rs1))
            rs1_sel = 2'b10;

        // rs2 forwarding
        if (m_regwren && (m_rd != 0) && (m_rd == e_rs2))
            rs2_sel = 2'b01;
        else if (w_regwren && (w_rd != 0) && (w_rd == e_rs2))
            rs2_sel = 2'b10;
    end

    // ===========================================================
    // WM forwarding (disabled here explicitly)
    // ===========================================================
    assign wm_fwd_sel = 1'b0;

endmodule : hazard_unit