`include "constants.svh"

module decode_tb;
    parameter int DWIDTH = 32;
    parameter int AWIDTH = 32;

    // Testbench signals
    logic clk;
    logic rst;
    logic [DWIDTH-1:0] insn_i;
    logic [AWIDTH-1:0] pc_i;

    logic [AWIDTH-1:0] pc_o;
    logic [DWIDTH-1:0] insn_o;
    logic [6:0] opcode_o;
    logic [4:0] rd_o;
    logic [4:0] rs1_o;
    logic [4:0] rs2_o;
    logic [6:0] funct7_o;
    logic [2:0] funct3_o;
    logic [4:0] shamt_o;  // shift amount
    logic [DWIDTH-1:0] imm_o;

    // Instantiate the decode module
    decode #( .DWIDTH(DWIDTH), .AWIDTH(AWIDTH) ) dut (
        .clk(clk),
        .rst(rst),
        .insn_i(insn_i),
        .pc_i(pc_i),
        .pc_o(pc_o),
        .insn_o(insn_o),
        .opcode_o(opcode_o),
        .rd_o(rd_o),
        .rs1_o(rs1_o),
        .rs2_o(rs2_o),
        .funct7_o(funct7_o),
        .funct3_o(funct3_o),
        .shamt_o(shamt_o),
        .imm_o(imm_o)
    );

    // Clock generation
    // initial begin
    //     clk = 0;
    //     forever #5 clk = ~clk; // 10 time units clock period
    // end

    // Test sequence
    initial begin
        // Initialize inputs
        //rst = 1;
        insn_i = 32'b0;
        pc_i = 32'b0;

        // Release reset after some time
        #15;
        //rst = 0;

        // Test case 1: R-type instruction (ADD x1, x2, x3)
        insn_i = 32'b0000000_00011_00010_000_00001_0110011; // ADD x1, x2, x3
        pc_i = 32'h00000000;
        #10; // Wait for a clock cycle

        // Display outputs for verification
        $display("Test Case 1: R-type ADD");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        $display("");
        
        // Test case 2: I-type instruction (ADDI x1, x2, 10)
        insn_i = 32'b000000000010_00010_000_00001_0010011; // ADDI x1, x2, 2
        pc_i = 32'h00000004;
        #10; // Wait for a clock cycle
        $display("Test Case 2: I-type ADDI");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        $display("");
        
        // Test case 3: Load instruction (LW x1, 0(x2))
        insn_i = 32'b000000000000_00010_010_00001_0000011; // LW x1, 0(x2)
        pc_i = 32'h00000008;
        #10; // Wait for a clock cycle
        $display("Test Case 3: Load LW");
        $display("Opcode: %b, rd: %d, rs1: %d, rs2: %d, funct3: %b, funct7: %b, imm: %d", 
                 opcode_o, rd_o, rs1_o, rs2_o, funct3_o, funct7_o, imm_o);
        $display("");
    end
endmodule : decode_tb