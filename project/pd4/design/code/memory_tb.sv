`include "constants.svh"

module memory_tb;
    // Clock period
    localparam int CLK_PERIOD = 10;
    
    // Parameters
    localparam int AWIDTH = 32;
    localparam int DWIDTH = 32;
    localparam logic [31:0] BASE_ADDR = 32'h01000000;
    
    // Inputs
    logic clk;
    logic rst;
    logic [AWIDTH-1:0] addr_i;
    logic [DWIDTH-1:0] data_i;
    logic read_en_i;
    logic write_en_i;
    logic [2:0] funct3_i;
    
    // Outputs
    logic [DWIDTH-1:0] data_o;
    
    // Instantiate the memory module
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) dut (
        .clk(clk),
        .rst(rst),
        .addr_i(addr_i),
        .data_i(data_i),
        .read_en_i(read_en_i),
        .write_en_i(write_en_i),
        .funct3_i(funct3_i),
        .data_o(data_o)
    );
    
    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Reset task
    task automatic reset_dut();
        begin
            rst = 1;
            read_en_i = 0;
            write_en_i = 0;
            addr_i = BASE_ADDR;
            data_i = '0;
            funct3_i = 3'b000;
            repeat (2) @(posedge clk);
            rst = 0;
            @(posedge clk);
        end
    endtask

    // Write task with funct3 support
    task automatic write_to_memory(
        input logic [AWIDTH-1:0] address, 
        input logic [DWIDTH-1:0] data,
        input logic [2:0] funct3
    );
        begin
            @(posedge clk);
            addr_i = address;
            data_i = data;
            funct3_i = funct3;
            write_en_i = 1;
            read_en_i = 0;
            @(posedge clk);
            write_en_i = 0;
        end
    endtask

    // Read task with funct3 support
    task automatic read_from_memory(
        input logic [AWIDTH-1:0] address,
        input logic [2:0] funct3
    );
        begin
            @(posedge clk);
            addr_i = address;
            funct3_i = funct3;
            write_en_i = 0;
            read_en_i = 1;
            @(posedge clk);
            read_en_i = 0;
        end
    endtask

    // Main test sequence
    initial begin
        $display("=== Memory Testbench Started ===");
        
        reset_dut();
        
        // Test 1: Word write and read
        $display("\n--- Test 1: Word Write/Read ---");
        write_to_memory(BASE_ADDR, 32'hDEADBEEF, FUNCT3_SW);
        read_from_memory(BASE_ADDR, FUNCT3_LW);
        #1; // Wait for combinational logic
        $display("Expected: 0xDEADBEEF, Got: 0x%08h", data_o);
        assert(data_o == 32'hDEADBEEF) else $error("Word read mismatch!");

        // Test 2: Halfword write and read
        $display("\n--- Test 2: Halfword Write/Read ---");
        write_to_memory(BASE_ADDR + 4, 32'h0000A5A5, FUNCT3_SH);
        read_from_memory(BASE_ADDR + 4, FUNCT3_LHU);
        #1;
        $display("Expected: 0x0000A5A5, Got: 0x%08h", data_o);
        assert(data_o == 32'h0000A5A5) else $error("Halfword unsigned read mismatch!");

        // Test 3: Signed halfword read
        $display("\n--- Test 3: Signed Halfword Read ---");
        write_to_memory(BASE_ADDR + 8, 32'h0000FFFF, FUNCT3_SH);
        read_from_memory(BASE_ADDR + 8, FUNCT3_LH);
        #1;
        $display("Expected: 0xFFFFFFFF, Got: 0x%08h", data_o);
        assert(data_o == 32'hFFFFFFFF) else $error("Signed halfword read mismatch!");

        // Test 4: Byte write and read
        $display("\n--- Test 4: Byte Write/Read ---");
        write_to_memory(BASE_ADDR + 12, 32'h000000AB, FUNCT3_SB);
        read_from_memory(BASE_ADDR + 12, FUNCT3_LBU);
        #1;
        $display("Expected: 0x000000AB, Got: 0x%08h", data_o);
        assert(data_o == 32'h000000AB) else $error("Byte unsigned read mismatch!");

        // Test 5: Signed byte read
        $display("\n--- Test 5: Signed Byte Read ---");
        write_to_memory(BASE_ADDR + 16, 32'h000000FF, FUNCT3_SB);
        read_from_memory(BASE_ADDR + 16, FUNCT3_LB);
        #1;
        $display("Expected: 0xFFFFFFFF, Got: 0x%08h", data_o);
        assert(data_o == 32'hFFFFFFFF) else $error("Signed byte read mismatch!");

        // Test 6: Multiple word writes
        $display("\n--- Test 6: Sequential Word Writes ---");
        write_to_memory(BASE_ADDR + 20, 32'h12345678, FUNCT3_SW);
        write_to_memory(BASE_ADDR + 24, 32'h9ABCDEF0, FUNCT3_SW);
        write_to_memory(BASE_ADDR + 28, 32'hFEDCBA98, FUNCT3_SW);
        
        read_from_memory(BASE_ADDR + 20, FUNCT3_LW);
        #1;
        $display("Address +20: Expected: 0x12345678, Got: 0x%08h", data_o);
        
        read_from_memory(BASE_ADDR + 24, FUNCT3_LW);
        #1;
        $display("Address +24: Expected: 0x9ABCDEF0, Got: 0x%08h", data_o);
        
        read_from_memory(BASE_ADDR + 28, FUNCT3_LW);
        #1;
        $display("Address +28: Expected: 0xFEDCBA98, Got: 0x%08h", data_o);

        // Test 7: Address wrapping test
        $display("\n--- Test 7: Address Wrapping ---");
        write_to_memory(32'h00000100, 32'hAAAAAAAA, FUNCT3_SW);
        read_from_memory(32'h00000100, FUNCT3_LW);
        #1;
        $display("Low address write/read: 0x%08h", data_o);

        // Finish simulation
        #20;
        $display("\n=== Memory Testbench Completed ===");
        $finish;
    end

endmodule : memory_tb