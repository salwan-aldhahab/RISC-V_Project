`include "constants.svh"

module register_file_tb;
    parameter int DWIDTH = 32;

    // Testbench signals - connecting to our register file
    logic clk_tb;                           // Clock signal
    logic rst_tb;                           // Reset signal
    logic [4:0] rs1_tb;                     // Register source 1 address
    logic [4:0] rs2_tb;                     // Register source 2 address
    logic [4:0] rd_tb;                      // Register destination address
    logic [DWIDTH-1:0] datawb_tb;           // Data to write back
    logic regwren_tb;                       // Register write enable
    logic [DWIDTH-1:0] rs1data_tb;          // Register source 1 data output
    logic [DWIDTH-1:0] rs2data_tb;          // Register source 2 data output

    // Test counters
    int pass_count = 0;
    int fail_count = 0;
    int total_tests = 0;

    // Clock generation
    always #5 clk_tb = ~clk_tb;

    // Create an instance of our register file under test
    register_file #( .DWIDTH(DWIDTH) ) register_file_dut (
        .clk(clk_tb),
        .rst(rst_tb),
        .rs1_i(rs1_tb),
        .rs2_i(rs2_tb),
        .rd_i(rd_tb),
        .datawb_i(datawb_tb),
        .regwren_i(regwren_tb),
        .rs1data_o(rs1data_tb),
        .rs2data_o(rs2data_tb)
    );

    // Run our test scenarios
    initial begin
        $display("=== Starting Register File Tests ===\n");
        
        // Initialize signals
        clk_tb = 0;
        rst_tb = 0;
        rs1_tb = 0;
        rs2_tb = 0;
        rd_tb = 0;
        datawb_tb = 0;
        regwren_tb = 0;

        // Test 1: Reset functionality
        total_tests++;
        $display("Test 1: Reset functionality");
        rst_tb = 1;
        #20;
        rst_tb = 0;
        #10;
        
        // Check x0 is zero and x2 is stack pointer
        rs1_tb = 5'd0;
        rs2_tb = 5'd2;
        #10;
        $display("  Result: x0=0x%08h, x2=0x%08h (Expected: x0=0x00000000, x2=0x01100000)", rs1data_tb, rs2data_tb);
        if (rs1data_tb == 32'h00000000 && rs2data_tb == 32'h01100000) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 2: Write to x0 (should remain zero)
        total_tests++;
        $display("Test 2: Write to x0 (should remain zero)");
        rd_tb = 5'd0;
        datawb_tb = 32'hDEADBEEF;
        regwren_tb = 1;
        #20;
        regwren_tb = 0;
        
        rs1_tb = 5'd0;
        #10;
        $display("  Result: x0=0x%08h (Expected: x0=0x00000000)", rs1data_tb);
        if (rs1data_tb == 32'h00000000) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 3: Write to x1 and read back
        total_tests++;
        $display("Test 3: Write to x1 and read back");
        rd_tb = 5'd1;
        datawb_tb = 32'h12345678;
        regwren_tb = 1;
        #20;
        regwren_tb = 0;
        
        rs1_tb = 5'd1;
        #10;
        $display("  Result: x1=0x%08h (Expected: x1=0x12345678)", rs1data_tb);
        if (rs1data_tb == 32'h12345678) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 4: Write to x31 (last register)
        total_tests++;
        $display("Test 4: Write to x31 (last register)");
        rd_tb = 5'd31;
        datawb_tb = 32'hABCDEF00;
        regwren_tb = 1;
        #20;
        regwren_tb = 0;
        
        rs1_tb = 5'd31;
        #10;
        $display("  Result: x31=0x%08h (Expected: x31=0xABCDEF00)", rs1data_tb);
        if (rs1data_tb == 32'hABCDEF00) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 5: Read from two registers simultaneously
        total_tests++;
        $display("Test 5: Read from two registers simultaneously (x1 and x31)");
        rs1_tb = 5'd1;
        rs2_tb = 5'd31;
        #10;
        $display("  Result: rs1=0x%08h, rs2=0x%08h (Expected: rs1=0x12345678, rs2=0xABCDEF00)", rs1data_tb, rs2data_tb);
        if (rs1data_tb == 32'h12345678 && rs2data_tb == 32'hABCDEF00) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 6: Write without enable (should not write)
        total_tests++;
        $display("Test 6: Write without enable (should not write)");
        rd_tb = 5'd5;
        datawb_tb = 32'hBADDATA1;
        regwren_tb = 0;  // Write enable is off
        #20;
        
        rs1_tb = 5'd5;
        #10;
        $display("  Result: x5=0x%08h (Expected: x5=0x00000000)", rs1data_tb);
        if (rs1data_tb == 32'h00000000) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 7: Overwrite existing register
        total_tests++;
        $display("Test 7: Overwrite existing register (x1)");
        rd_tb = 5'd1;
        datawb_tb = 32'h87654321;
        regwren_tb = 1;
        #20;
        regwren_tb = 0;
        
        rs1_tb = 5'd1;
        #10;
        $display("  Result: x1=0x%08h (Expected: x1=0x87654321)", rs1data_tb);
        if (rs1data_tb == 32'h87654321) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 8: Write to multiple registers sequentially
        total_tests++;
        $display("Test 8: Write to multiple registers sequentially");
        regwren_tb = 1;
        
        // Write to x10
        rd_tb = 5'd10;
        datawb_tb = 32'h11111111;
        #20;
        
        // Write to x20
        rd_tb = 5'd20;
        datawb_tb = 32'h22222222;
        #20;
        
        regwren_tb = 0;
        
        // Read both
        rs1_tb = 5'd10;
        rs2_tb = 5'd20;
        #10;
        $display("  Result: x10=0x%08h, x20=0x%08h (Expected: x10=0x11111111, x20=0x22222222)", rs1data_tb, rs2data_tb);
        if (rs1data_tb == 32'h11111111 && rs2data_tb == 32'h22222222) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 9: x0 always reads as zero (even after other operations)
        total_tests++;
        $display("Test 9: x0 always reads as zero");
        rs1_tb = 5'd0;
        rs2_tb = 5'd0;
        #10;
        $display("  Result: x0(rs1)=0x%08h, x0(rs2)=0x%08h (Expected: both=0x00000000)", rs1data_tb, rs2data_tb);
        if (rs1data_tb == 32'h00000000 && rs2data_tb == 32'h00000000) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Test 10: Stack pointer preservation (x2 should still be stack pointer)
        total_tests++;
        $display("Test 10: Stack pointer preservation");
        rs1_tb = 5'd2;
        #10;
        $display("  Result: x2=0x%08h (Expected: x2=0x01100000)", rs1data_tb);
        if (rs1data_tb == 32'h01100000) begin
            $display("  Status: PASS\n");
            pass_count++;
        end else begin
            $display("  Status: FAIL\n");
            fail_count++;
        end

        // Display final results
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

endmodule : register_file_tb