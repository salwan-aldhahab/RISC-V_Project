import constants_pkg::*;

module pd0_testbench;

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

  // Clock just toggle every 5ns
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
    
    // Test the ALU 
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

    // Test the register just store and read back some values
    $display("\n--- Testing Register ---");
    
    // Check initial state after reset
    $display("Initial register value: %0d", reg_data_out);
    
    // Set input, wait for clock, then check output
    reg_data_in = 42;
    @(posedge clk);
    #1; // Small delay after clock edge
    $display("After storing 42: %0d", reg_data_out);
    
    reg_data_in = 123;
    @(posedge clk);
    #1; 
    $display("After storing 123: %0d", reg_data_out);
    
    // Test reset functionality, reset should take effect immediately on clock edge
    reg_data_in = 99; // Set some value
    rst = 1;
    @(posedge clk);
    #1;
    $display("After reset: %0d (should be 0)", reg_data_out);
    rst = 0;
    @(posedge clk);

    // Test the pipeline
    $display("\n--- Testing Pipeline ---");
    
    // Apply first input
    pipe_in1 = 100; pipe_in2 = 25;
    $display("Cycle 1 - Input: op1=%0d, op2=%0d", pipe_in1, pipe_in2);
    @(posedge clk);
    
    // Apply second input  
    pipe_in1 = 50; pipe_in2 = 30; 
    $display("Cycle 2 - Input: op1=%0d, op2=%0d, Output: %0d", pipe_in1, pipe_in2, pipe_out);
    @(posedge clk);
    
    // Third cycle 
    pipe_in1 = 75; pipe_in2 = 10;
    $display("Cycle 3 - Input: op1=%0d, op2=%0d, Output: %0d", pipe_in1, pipe_in2, pipe_out);
    @(posedge clk);
    
    // Fourth cycle - first result should appear here
    pipe_in1 = 0; pipe_in2 = 0;
    $display("Cycle 4 - Output: %0d (should be 25 from cycle 1)", pipe_out);
    @(posedge clk);
    
    // Fifth cycle - second result appears
    $display("Cycle 5 - Output: %0d (should be 30 from cycle 2)", pipe_out);
    @(posedge clk);
    
    // Sixth cycle - third result appears
    $display("Cycle 6 - Output: %0d (should be 10 from cycle 3)", pipe_out);
    @(posedge clk);
    
    // Seventh cycle - should see 0 now
    $display("Cycle 7 - Output: %0d (should be 0)", pipe_out);
    
    // All done
    $display("\nTests finished!");
    $finish;
  end

endmodule