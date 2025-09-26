`timescale 1ns/1ps

// Testbench for: alu.sv, reg_rst.sv, three_stage_pipeline.sv
// File: pd0_tb.sv
// Generates a clock/reset, exercises each module, and produces a VCD for waveforms.
// Works with ModelSim/Questa (via vsim + "log -r /*; add wave -r /*") and with Verilator/Icarus (via $dumpvars).

import constants_pkg::*;

module pd0_tb;

  // ---------------------------------------------------------------------------
  // Parameters & signals
  // ---------------------------------------------------------------------------
  localparam int DWIDTH = 8;

  // Clock & reset
  logic clk;
  logic rst;

  // ALU I/O
  logic [DWIDTH-1:0] alu_op1, alu_op2;
  logic [1:0]        alu_sel;
  logic [DWIDTH-1:0] alu_res;
  logic              alu_zero, alu_neg;

  // REG_RSR I/O
  logic [DWIDTH-1:0] reg_in;
  logic [DWIDTH-1:0] reg_out;

  // TSP I/O
  logic [DWIDTH-1:0] tsp_op1, tsp_op2;
  logic [DWIDTH-1:0] tsp_res;

  // ---------------------------------------------------------------------------
  // DUT Instantiations
  // ---------------------------------------------------------------------------
  // ALU
  alu #(.DWIDTH(DWIDTH)) u_alu (
    .sel_i (alu_sel),
    .op1_i (alu_op1),
    .op2_i (alu_op2),
    .res_o (alu_res),
    .zero_o(alu_zero),
    .neg_o (alu_neg)
  );

  // Register with synchronous reset
  reg_rst #(.DWIDTH(DWIDTH)) u_reg (
    .clk   (clk),
    .rst   (rst),
    .in_i  (reg_in),
    .out_o (reg_out)
  );

  // Three-stage pipeline
  three_stage_pipeline #(.DWIDTH(DWIDTH)) u_tsp (
    .clk   (clk),
    .rst   (rst),
    .op1_i (tsp_op1),
    .op2_i (tsp_op2),
    .res_o (tsp_res)
  );

  // ---------------------------------------------------------------------------
  // Clock & reset generation
  // ---------------------------------------------------------------------------
  // 100 MHz clock (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // Active-high synchronous reset: hold high for a few cycles
  initial begin
    rst = 1'b1;
    repeat (3) @(posedge clk);
    rst = 1'b0;
  end

  // ---------------------------------------------------------------------------
  // VCD dump for waveform viewers (Verilator/Icarus etc.)
  // ---------------------------------------------------------------------------
  initial begin
    $dumpfile("pd0_tb.vcd");
    $dumpvars(0, pd0_tb);
  end

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  task automatic drive_alu(input logic [DWIDTH-1:0] a,
                           input logic [DWIDTH-1:0] b,
                           input aluSel_e           sel);
    begin
      alu_op1 = a;
      alu_op2 = b;
      alu_sel = sel;
      // ALU is combinational; wait a delta and then a cycle to align prints
      #1;
      $display("[%0t] ALU sel=%0d op1=%0d op2=%0d -> res=%0d zero=%0b neg=%0b",
               $time, sel, a, b, alu_res, alu_zero, alu_neg);
      @(posedge clk);
    end
  endtask

  // For the 3-stage pipeline, the expected function is: res_o = (op1 + op2) - op1 = op2,
  // but it appears TWO cycles later due to the registers.
  typedef struct packed {logic [DWIDTH-1:0] expect;} exp_t;
  exp_t exp_q[$];

  task automatic push_expect(input logic [DWIDTH-1:0] expect);
    exp_t e; e.expect = expect; exp_q.push_back(e);
  endtask

  // Pop/compare after the two-cycle latency has elapsed (we'll manage timing in the stimulus)
  task automatic check_tsp(input string tag);
    if (exp_q.size() != 0) begin
      exp_t e = exp_q.pop_front();
      if (tsp_res !== e.expect) begin
        $error("[%0t] TSP %s: expected %0d, got %0d", $time, tag, e.expect, tsp_res);
      end else begin
        $display("[%0t] TSP %s: PASS expect=%0d got=%0d", $time, tag, e.expect, tsp_res);
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test stimulus
  // ---------------------------------------------------------------------------
  initial begin : STIMULUS
    // Default drives
    alu_op1 = '0; alu_op2 = '0; alu_sel = ADD;
    reg_in  = '0;
    tsp_op1 = '0; tsp_op2 = '0;

    // Wait for reset deassertion
    @(negedge rst);
    @(posedge clk);

    // ---------------- ALU tests ----------------
    drive_alu(8'd10, 8'd3, ADD);
    drive_alu(8'd10, 8'd3, SUB);
    drive_alu(8'hF0, 8'h0F, AND);
    drive_alu(8'hA5, 8'h5A, OR);

    // ---------------- REG_RSR tests ----------------
    // Show synchronous reset behavior and registered capture
    reg_in = 8'd9;
    @(posedge clk);
    // reg_out should now be 9
    $display("[%0t] REG step1: in=%0d out=%0d", $time, reg_in, reg_out);
    reg_in = 8'd8;
    @(posedge clk);
    $display("[%0t] REG step2: in=%0d out=%0d", $time, reg_in, reg_out);
    // Assert reset for one cycle; out should clear to 0 at next clock
    rst = 1'b1; @(posedge clk);
    $display("[%0t] REG reset : in=%0d out=%0d (expect 0)", $time, reg_in, reg_out);
    rst = 1'b0; @(posedge clk);

    // ---------------- TSP tests ----------------
    // Apply a few vectors; remember output appears two cycles later and equals op2
    tsp_op1 = 8'd5;  tsp_op2 = 8'd21; push_expect(8'd21); @(posedge clk);
    tsp_op1 = 8'd12; tsp_op2 = 8'd7;  push_expect(8'd7 ); @(posedge clk);
    // idle input; still advancing pipeline
    tsp_op1 = 8'd0;  tsp_op2 = 8'd0;                        @(posedge clk);

    // Now, after two cycles from the first vector, begin checking on each cycle
    repeat (3) begin
      check_tsp("pipe");
      @(posedge clk);
    end

    // Finish
    $display("[%0t] TEST COMPLETE", $time);
    #10;
    $finish;
  end

endmodule
