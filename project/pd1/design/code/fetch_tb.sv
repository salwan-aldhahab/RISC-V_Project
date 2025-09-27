module fetch_tb;
    // clock period
    localparam int CLK_PERIOD = 10;
    // parameters
    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;
    localparam logic [31:0] BASEADDR = 32'h01000000;
    // inputs
    logic clk;
    logic rst;
    // outputs
    logic [AWIDTH - 1:0] pc_o;
    logic [DWIDTH - 1:0] insn_o;
    // Instantiate the fetch module
    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASEADDR(BASEADDR)
    ) dut (
        .clk(clk),
        .rst(rst),
        .pc_o(pc_o),
        .insn_o(insn_o)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    // Reset generation
    task automatic reset_dut();
        begin
            rst = 1;
            repeat (2) @(posedge clk);
            rst = 0;
            @(posedge clk);
        end
    endtask

    task automatic check_output(input logic [AWIDTH-1:0] expected_pc, input logic [DWIDTH-1:0] expected_insn);
        begin
            if (pc_o !== expected_pc) begin
                $error("PC Mismatch: Expected %h, Got %h", expected_pc, pc_o);
            end else begin
                $display("PC Match: %h", pc_o);
            end
            if (insn_o !== expected_insn) begin
                $error("Instruction Mismatch: Expected %h, Got %h", expected_insn, insn_o);
            end else begin
                $display("Instruction Match: %h", insn_o);
            end
        end
    endtask

    initial begin
        // Initialize inputs
        reset_dut();
        
        // Check outputs against expected values
        // Assuming mem_init.hex has been initialized with known values
        check_output(BASEADDR, 32'hA3B2C1D0); // NOP instruction at BASEADDR
        @(posedge clk);
        check_output(BASEADDR + 4, 32'hF8E7D6C5); // NOP instruction at BASEADDR + 4
        @(posedge clk);
        check_output(BASEADDR + 8, 32'h12345678); // NOP instruction at BASEADDR + 8
        @(posedge clk);
        check_output(BASEADDR + 12, 32'h9ABCDEF0); // NOP instruction at BASEADDR + 12
        @(posedge clk);
        $display("Fetch module test completed.");
        $finish;
    end

endmodule: fetch_tb