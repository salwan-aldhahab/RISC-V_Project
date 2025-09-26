`timescale 1ns/1ps

// Simple testbench for ALU, register, and 3-stage pipeline
// Just runs some basic tests and dumps waveforms

import constants_pkg::*;

module pd0_testbench;

  // Basic stuff
  parameter DWIDTH = 8;
  
  logic clk = 0;
  logic rst;

  // ALU signals
  logic [DWIDTH-1:0] alu_a, alu_b, alu_result;
  logic [1:0] alu_op;
  logic zero_flag, neg_flag;

  // Register signals  
  logic [DWIDTH-1:0] reg_data_in, reg_data_out;

  // Pipeline signals
  logic [DWIDTH-1:0] pipe_in1, pipe_in2, pipe_out;

  // Instantiate the modules
  alu #(.DWIDTH(DWIDTH)) my_alu (
    .sel_i(alu_op),
    .op1_i(alu_a),
    .op2_i(alu_b), 
    .res_o(alu_result),
    .zero_o(zero_flag),
    .neg_o(neg_flag)
  );

  reg_rst #(.DWIDTH(DWIDTH)) my_reg (
    .clk(clk),
    .rst(rst),
    .in_i(reg_data_in),
    .out_o(reg_data_out)
  );

  three_stage_pipeline #(.DWIDTH(DWIDTH)) my_pipeline (
    .clk(clk),
    .rst(rst), 
    .op1_i(pipe_in1),
    .op2_i(pipe_in2),
    .res_o(pipe_out)
  );

  // Clock - just toggle every 5ns
  always #5 clk = ~clk;

  // Dump waveforms
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
  end

  // Main test
  initial begin
    // Start with reset
    rst = 1;
    alu_a = 0; alu_b = 0; alu_op = ADD;
    reg_data_in = 0;
    pipe_in1 = 0; pipe_in2 = 0;
    
    // Wait a few clock cycles then release reset
    repeat(3) @(posedge clk);
    rst = 0;
    @(posedge clk);
    
    $display("Starting tests...");
    
    // Test the ALU with some simple operations
    $display("\n--- Testing ALU ---");
    alu_a = 15; alu_b = 10; alu_op = ADD;
    #1;  // Small delay for combinational logic to settle
    $display("ADD: %0d + %0d = %0d (zero=%b, neg=%b)", alu_a, alu_b, alu_result, zero_flag, neg_flag);
    
    alu_a = 20; alu_b = 5; alu_op = SUB; 
    #1;
    $display("SUB: %0d - %0d = %0d (zero=%b, neg=%b)", alu_a, alu_b, alu_result, zero_flag, neg_flag);
    
    alu_a = 8'hAA; alu_b = 8'h55; alu_op = AND;
    #1; 
    $display("AND: 0x%h & 0x%h = 0x%h", alu_a, alu_b, alu_result);
    
    alu_a = 8'hA0; alu_b = 8'h05; alu_op = OR;
    #1;
    $display("OR:  0x%h | 0x%h = 0x%h", alu_a, alu_b, alu_result);

    // Test the register - just store and read back some values
    $display("\n--- Testing Register ---");
    reg_data_in = 42;
    @(posedge clk);
    $display("Stored %0d, read back %0d", reg_data_in, reg_data_out);
    
    reg_data_in = 123;
    @(posedge clk); 
    $display("Stored %0d, read back %0d", reg_data_in, reg_data_out);
    
    // Test reset functionality
    rst = 1;
    @(posedge clk);
    $display("After reset: %0d (should be 0)", reg_data_out);
    rst = 0;
    @(posedge clk); // Wait one more cycle after reset

    // Test the pipeline - results come out 2 cycles later
    $display("\n--- Testing Pipeline ---");
    pipe_in1 = 100; pipe_in2 = 25;
    $display("Input: op1=%0d, op2=%0d", pipe_in1, pipe_in2);
    @(posedge clk);
    
    pipe_in1 = 50; pipe_in2 = 30; 
    $display("Input: op1=%0d, op2=%0d", pipe_in1, pipe_in2);
    @(posedge clk);
    
    // Now check outputs - should see first result
    pipe_in1 = 0; pipe_in2 = 0;
    $display("Pipeline output: %0d (should be 25)", pipe_out);
    @(posedge clk);
    
    $display("Pipeline output: %0d (should be 30)", pipe_out);
    @(posedge clk);
    
    // All done
    $display("\nTests finished!");
    $finish;
  end

endmodule