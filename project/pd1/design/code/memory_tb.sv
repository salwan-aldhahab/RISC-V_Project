module memory_tb;
    // clock period
    localparam int CLK_PERIOD = 10;
    
    // parameters
    localparam int AWIDTH = 32;
    localparam int DWIDTH = 32;
    localparam logic [31:0] BASE_ADDR = 32'h01000000;
    
    // inputs
    logic clk;
    logic rst;
    logic [AWIDTH-1:0] addr_i;
    logic [DWIDTH-1:0] data_i;
    logic read_en_i;
    logic write_en_i;
    
    // outputs
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
        .data_o(data_o)
    );
    
    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Reset generation
    task automatic reset_dut();
        begin
            rst = 1;
            read_en_i = 0;
            write_en_i = 0;
            addr_i = BASE_ADDR;
            data_i = '0;
            repeat (2) @(posedge clk);
            rst = 0;
            @(posedge clk);
        end
    endtask

    task automatic write_to_memory(input logic [AWIDTH-1:0] address, input logic [DWIDTH-1:0] data);
        begin
            @(posedge clk);
            addr_i = address;
            data_i = data;
            write_en_i = 1;
            read_en_i = 0;
            @(posedge clk);
            write_en_i = 0; // Deassert write enable after one clock cycle
        end
    endtask

    task automatic read_from_memory(input logic [AWIDTH-1:0] address);
        begin
            @(posedge clk);
            addr_i = address;
            write_en_i = 0;
            read_en_i = 1;
            @(posedge clk);
            read_en_i = 0; // Deassert read enable after one clock cycle
        end
    endtask

    initial begin
        reset_dut();
        
        write_to_memory(BASE_ADDR, 32'hDEADBEEF);
        read_from_memory(BASE_ADDR);
        $display("Data read from address %h: %h", BASE_ADDR, data_o);

        write_to_memory(BASE_ADDR + 4, 32'hA5A5A5A5);
        read_from_memory(BASE_ADDR + 4);
        $display("Data read from address %h: %h", BASE_ADDR + 4, data_o);
        
        write_to_memory(BASE_ADDR + 8, 32'h5A5A5A5A);
        read_from_memory(BASE_ADDR + 8);
        $display("Data read from address %h: %h", BASE_ADDR + 8, data_o);
        
        // Finish simulation
        #20;
        $finish;
    end
    

//     // Test sequence
//     initial begin
//         // Initialize inputs
//         rst = 1;
//         addr_i = BASE_ADDR;
//         data_i = '0;
//         read_en_i = 0;
//         write_en_i = 0;
    
//         // Apply reset
//         #10;
//         rst = 0;
    
//         // Wait for a few clock cycles
//         #20;
    
//         // Test read operation
//         read_en_i = 1;
//         addr_i = BASE_ADDR; // Address to read from
//         #10; // Wait for one clock cycle
//         $display("Read Data at address %h: %h", addr_i, data_o);
    
//         // Test write operation (if applicable)
//         read_en_i = 0;
//         write_en_i = 1;
//         addr_i = BASE_ADDR + 4; // Address to write to
//         data_i = 32'hDEADBEEF;   // Data to write
//         #10; // Wait for one clock cycle
    
//         // Verify write by reading back the data
//         write_en_i = 0;
//         read_en_i = 1;
//         #10; // Wait for one clock cycle
//         $display("Read Data at address %h after write: %h", addr_i, data_o);
    
//         // Finish simulation
endmodule: memory_tb