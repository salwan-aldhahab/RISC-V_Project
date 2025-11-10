`timescale 1ns/1ps
`include "constants.svh"

module writeback_tb;
  // Parameters
  parameter int DWIDTH = 32;
  parameter int AWIDTH = 32;

  // Local encodings for wbsel (match your RTL intent)
  localparam logic [1:0] WBSEL_ALU  = 2'b00;
  localparam logic [1:0] WBSEL_MEM  = 2'b01;
  localparam logic [1:0] WBSEL_PC4  = 2'b10;
  localparam logic [1:0] WBSEL_DEF  = 2'b11; // default case in RTL -> writeback_data_o = '0

  // DUT I/O
  logic [AWIDTH-1:0] pc_tb;
  logic [DWIDTH-1:0] alu_res_tb;
  logic [DWIDTH-1:0] memory_data_tb;
  logic [1:0]        wbsel_tb;
  logic              brtaken_tb;
  logic [DWIDTH-1:0] writeback_data_tb;
  logic [AWIDTH-1:0] next_pc_tb;

  // Test counters
  int pass_count = 0;
  int fail_count = 0;
  int total_tests = 0;

  // Device Under Test
  writeback #(
    .DWIDTH(DWIDTH),
    .AWIDTH(AWIDTH)
  ) dut (
    .pc_i(pc_tb),
    .alu_res_i(alu_res_tb),
    .memory_data_i(memory_data_tb),
    .wbsel_i(wbsel_tb),
    .brtaken_i(brtaken_tb),
    .writeback_data_o(writeback_data_tb),
    .next_pc_o(next_pc_tb)
  );

  // Helper task for checking results
  task automatic check(
    input string name,
    input logic [DWIDTH-1:0] exp_wb,
    input logic [AWIDTH-1:0] exp_nextpc
  );
    total_tests++;
    #10; // allow combinational settle
    $display("  Result: writeback_data=0x%08h, next_pc=0x%08h", writeback_data_tb, next_pc_tb);
    if (writeback_data_tb === exp_wb && next_pc_tb === exp_nextpc) begin
      $display("  Status: PASS\n");
      pass_count++;
    end else begin
      $display("  Status: FAIL (Expected wb=0x%08h, next_pc=0x%08h)\n", exp_wb, exp_nextpc);
      fail_count++;
    end
  endtask

  // Tests
  initial begin
    $display("=== Starting Writeback Tests ===\n");

    // Common inits
    pc_tb          = 32'h00000064;         // 100
    alu_res_tb     = 32'hDEADBEEF;
    memory_data_tb = 32'hCAFEBABE;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;

    // Test 1: wbsel = ALU, no branch -> wb = ALU, next_pc = pc + 4
    $display("Test 1: wbsel=ALU, brtaken=0 (pc=0x%08h)", pc_tb);
    wbsel_tb   = WBSEL_ALU;
    brtaken_tb = 1'b0;
    check("T1", alu_res_tb, pc_tb + 32'd4);

    // Test 2: wbsel = MEM, no branch -> wb = MEM, next_pc = pc + 4
    $display("Test 2: wbsel=MEM, brtaken=0");
    wbsel_tb   = WBSEL_MEM;
    brtaken_tb = 1'b0;
    check("T2", memory_data_tb, pc_tb + 32'd4);

    // Test 3: wbsel = PC+4, no branch -> wb = pc+4, next_pc = pc + 4
    $display("Test 3: wbsel=PC+4, brtaken=0");
    wbsel_tb   = WBSEL_PC4;
    brtaken_tb = 1'b0;
    check("T3", pc_tb + 32'd4, pc_tb + 32'd4);

    // Test 4: Branch taken -> next_pc = ALU result; wb still follows wbsel (use MEM here)
    $display("Test 4: wbsel=MEM, brtaken=1 (next_pc should be ALU result)");
    wbsel_tb   = WBSEL_MEM;
    brtaken_tb = 1'b1;
    check("T4", memory_data_tb, alu_res_tb);

    // Test 5: Branch taken with wbsel=PC+4 -> wb = pc+4, next_pc = ALU result
    $display("Test 5: wbsel=PC+4, brtaken=1");
    wbsel_tb   = WBSEL_PC4;
    brtaken_tb = 1'b1;
    check("T5", pc_tb + 32'd4, alu_res_tb);

    // Test 6: Default wbsel (2'b11) -> wb = 0, no branch -> next_pc = pc + 4
    $display("Test 6: wbsel=default(11), brtaken=0 (writeback_data should be 0)");
    wbsel_tb   = WBSEL_DEF;
    brtaken_tb = 1'b0;
    check("T6", '0, pc_tb + 32'd4);

    // Test 7: Overflow edge case on pc+4 (pc near 0xFFFF_FFFC), no branch
    $display("Test 7: Overflow edge case (pc=0xFFFF_FFFC), wbsel=PC+4, brtaken=0");
    pc_tb      = 32'hFFFF_FFFC;
    wbsel_tb   = WBSEL_PC4;
    brtaken_tb = 1'b0;
    // 0xFFFF_FFFC + 4 wraps to 0x0000_0000 in 32-bit math
    check("T7", 32'h0000_0000, 32'h0000_0000);

    // Test 8: Same overflow PC but branch taken -> next_pc = ALU result
    $display("Test 8: Overflow PC, wbsel=ALU, brtaken=1 (next_pc from ALU)");
    wbsel_tb   = WBSEL_ALU;
    brtaken_tb = 1'b1;
    check("T8", alu_res_tb, alu_res_tb);

    // Summary
    $display("=== Test Summary ===");
    $display("Total Tests: %0d", total_tests);
    $display("Tests Passed: %0d", pass_count);
    $display("Tests Failed: %0d", fail_count);
    $display("Pass Rate: %0.1f%%", (real'(pass_count) / real'(total_tests)) * 100.0);

    if (fail_count == 0) begin
      $display("ALL TESTS PASSED!");
    end else begin
      $display("%0d test(s) failed. Check the implementation.", fail_count);
    end

    $display("=== All tests completed ===");
    $finish;
  end
endmodule : writeback_tb
