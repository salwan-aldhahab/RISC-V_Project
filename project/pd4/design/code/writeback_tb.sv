module writeback_tb;
  // Parameters
  parameter int DWIDTH = 32;
  parameter int AWIDTH = 32;

  // Local encodings for wbsel
  localparam logic [1:0] WBSEL_ALU  = 2'b00;
  localparam logic [1:0] WBSEL_MEM  = 2'b01;
  localparam logic [1:0] WBSEL_PC4  = 2'b10;
  localparam logic [1:0] WBSEL_DEF  = 2'b11;

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
    #10; 
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
    $display("=== Starting Writeback Stage Tests ===\n");

    // ========== ARITHMETIC INSTRUCTION TESTS (R-type) ==========
    $display("--- Arithmetic Instructions (R-type) ---");
    
    // Test 1: ADD instruction result writeback
    $display("Test 1: ADD x5, x3, x4 (result=0x12345678)");
    pc_tb          = 32'h00001000;
    alu_res_tb     = 32'h12345678;
    memory_data_tb = 32'h00000000;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("ADD", alu_res_tb, pc_tb + 32'd4);

    // Test 2: SUB instruction with negative result
    $display("Test 2: SUB x7, x1, x2 (result=0xFFFFFFF0, -16 in 2's complement)");
    pc_tb          = 32'h00001004;
    alu_res_tb     = 32'hFFFFFFF0;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("SUB", alu_res_tb, pc_tb + 32'd4);

    // Test 3: AND instruction
    $display("Test 3: AND x10, x8, x9 (result=0x0000FF00)");
    pc_tb          = 32'h00001008;
    alu_res_tb     = 32'h0000FF00;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("AND", alu_res_tb, pc_tb + 32'd4);

    // ========== LOAD INSTRUCTION TESTS ==========
    $display("--- Load Instructions ---");
    
    // Test 4: LW (Load Word) from memory
    $display("Test 4: LW x15, 0(x10) (loading 0xDEADBEEF from memory)");
    pc_tb          = 32'h0000100C;
    alu_res_tb     = 32'h00002000;  // Memory address computed
    memory_data_tb = 32'hDEADBEEF;
    wbsel_tb       = WBSEL_MEM;
    brtaken_tb     = 1'b0;
    check("LW", memory_data_tb, pc_tb + 32'd4);

    // Test 5: LB (Load Byte) - sign extended
    $display("Test 5: LB x20, 4(x11) (loading sign-extended byte 0xFFFFFF80)");
    pc_tb          = 32'h00001010;
    memory_data_tb = 32'hFFFFFF80;  // Sign-extended from 0x80
    wbsel_tb       = WBSEL_MEM;
    brtaken_tb     = 1'b0;
    check("LB", memory_data_tb, pc_tb + 32'd4);

    // ========== IMMEDIATE INSTRUCTION TESTS ==========
    $display("--- Immediate Instructions (I-type) ---");
    
    // Test 6: ADDI with large immediate
    $display("Test 6: ADDI x12, x13, 2047 (result=0x000007FF)");
    pc_tb          = 32'h00001014;
    alu_res_tb     = 32'h000007FF;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("ADDI", alu_res_tb, pc_tb + 32'd4);

    // Test 7: SLTI (Set Less Than Immediate)
    $display("Test 7: SLTI x14, x15, -5 (result=0x00000001, true)");
    pc_tb          = 32'h00001018;
    alu_res_tb     = 32'h00000001;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("SLTI", alu_res_tb, pc_tb + 32'd4);

    // ========== JAL/JALR INSTRUCTION TESTS ==========
    $display("--- Jump and Link Instructions ---");
    
    // Test 8: JAL - stores PC+4 and jumps
    $display("Test 8: JAL x1, label (PC=0x1000, target=0x1100)");
    pc_tb          = 32'h00001000;
    alu_res_tb     = 32'h00001100;  // Jump target
    wbsel_tb       = WBSEL_PC4;     // Store return address (PC+4)
    brtaken_tb     = 1'b0;
    check("JAL", pc_tb + 32'd4, alu_res_tb);

    // Test 9: JALR - indirect jump with return address
    $display("Test 9: JALR x1, 8(x5) (PC=0x2000, target=0x3008)");
    pc_tb          = 32'h00002000;
    alu_res_tb     = 32'h00003008;  // Computed jump target
    wbsel_tb       = WBSEL_PC4;
    brtaken_tb     = 1'b0;
    check("JALR", pc_tb + 32'd4, alu_res_tb);

    // ========== BRANCH INSTRUCTION TESTS ==========
    $display("--- Branch Instructions ---");
    
    // Test 10: BEQ taken - branch to target
    $display("Test 10: BEQ x10, x11, label (branch taken to 0x2100)");
    pc_tb          = 32'h00002000;
    alu_res_tb     = 32'h00002100;  // Branch target
    wbsel_tb       = WBSEL_ALU;     // Branch doesn't write back
    brtaken_tb     = 1'b1;
    check("BEQ_taken", alu_res_tb, alu_res_tb);

    // Test 11: BNE not taken - sequential execution
    $display("Test 11: BNE x12, x13, label (branch not taken)");
    pc_tb          = 32'h00003000;
    alu_res_tb     = 32'h00003100;  // Would-be branch target
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("BNE_not_taken", alu_res_tb, pc_tb + 32'd4);

    // Test 12: BLT taken - backward branch (loop)
    $display("Test 12: BLT x14, x15, loop_start (backward branch to 0x2FF0)");
    pc_tb          = 32'h00003000;
    alu_res_tb     = 32'h00002FF0;  // Loop back
    wbsel_tb       = WBSEL_MEM;     // No writeback for branch
    brtaken_tb     = 1'b1;
    check("BLT_backward", memory_data_tb, alu_res_tb);

    // ========== EDGE CASES ==========
    $display("--- Edge Cases and Boundary Conditions ---");
    
    // Test 13: Zero address handling
    $display("Test 13: Instruction at address 0x00000000");
    pc_tb          = 32'h00000000;
    alu_res_tb     = 32'h00000042;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("Zero_addr", alu_res_tb, 32'h00000004);

    // Test 14: Maximum positive value
    $display("Test 14: ALU result = 0x7FFFFFFF (max positive int)");
    pc_tb          = 32'h00004000;
    alu_res_tb     = 32'h7FFFFFFF;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("Max_pos", alu_res_tb, pc_tb + 32'd4);

    // Test 15: Minimum negative value
    $display("Test 15: Memory data = 0x80000000 (min negative int)");
    pc_tb          = 32'h00004004;
    memory_data_tb = 32'h80000000;
    wbsel_tb       = WBSEL_MEM;
    brtaken_tb     = 1'b0;
    check("Min_neg", memory_data_tb, pc_tb + 32'd4);

    // Test 16: PC overflow scenario
    $display("Test 16: PC near end of address space (0xFFFFFFFC)");
    pc_tb          = 32'hFFFFFFFC;
    alu_res_tb     = 32'hAAAAAAAA;
    wbsel_tb       = WBSEL_PC4;
    brtaken_tb     = 1'b0;
    check("PC_overflow", 32'h00000000, alu_res_tb);

    // Test 17: All zeros
    $display("Test 17: All input signals zero");
    pc_tb          = 32'h00000000;
    alu_res_tb     = 32'h00000000;
    memory_data_tb = 32'h00000000;
    wbsel_tb       = WBSEL_ALU;
    brtaken_tb     = 1'b0;
    check("All_zeros", 32'h00000000, 32'h00000004);

    // Test 18: All ones pattern
    $display("Test 18: All ones pattern (0xFFFFFFFF)");
    pc_tb          = 32'hFFFFFFFF;
    alu_res_tb     = 32'hFFFFFFFF;
    memory_data_tb = 32'hFFFFFFFF;
    wbsel_tb       = WBSEL_MEM;
    brtaken_tb     = 1'b0;
    check("All_ones", 32'hFFFFFFFF, 32'h00000003);

    // Test 19: Default/undefined wbsel
    $display("Test 19: Undefined wbsel (2'b11) - should output zero");
    pc_tb          = 32'h00005000;
    wbsel_tb       = WBSEL_DEF;
    brtaken_tb     = 1'b0;
    check("Undefined_wbsel", 32'h00000000, pc_tb + 32'd4);

    // Test 20: Rapid alternating branches
    $display("Test 20: Branch taken with PC+4 writeback (e.g., JAL in delay slot)");
    pc_tb          = 32'h00006000;
    alu_res_tb     = 32'h00007000;
    wbsel_tb       = WBSEL_PC4;
    brtaken_tb     = 1'b1;
    check("JAL_branch", pc_tb + 32'd4, alu_res_tb);

    // Summary
    $display("=== Test Summary ===");
    $display("Total Tests: %0d", total_tests);
    $display("Tests Passed: %0d", pass_count);
    $display("Tests Failed: %0d", fail_count);
    $display("Pass Rate: %0.1f%%", (real'(pass_count) / real'(total_tests)) * 100.0);

    if (fail_count == 0) begin
      $display("\n*** ALL TESTS PASSED! ***");
      $display("The writeback stage correctly handles:");
      $display("  - Arithmetic operations (R-type)");
      $display("  - Load instructions");
      $display("  - Immediate operations (I-type)");
      $display("  - Jump and link (JAL/JALR)");
      $display("  - Branch instructions (taken/not taken)");
      $display("  - Edge cases and boundary conditions");
    end else begin
      $display("\n*** %0d TEST(S) FAILED ***", fail_count);
      $display("Review the failed test cases above for details.");
    end

    $display("\n=== Writeback Stage Testing Complete ===");
    $finish;
  end
endmodule : writeback_tb
