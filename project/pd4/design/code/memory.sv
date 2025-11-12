/*
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 * Module: memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 * 2) data out valid signal data_vld_o
 */

/*
 * Module: memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write operations
 * with different access sizes (byte, halfword, word).
 * Reads are combinational and writes are performed on the rising clock edge.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 * 7) funct3 signal for load/store size and sign extension
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 */

`include "constants.svh"

module memory #(
  // parameters
  parameter int AWIDTH = 32,
  parameter int DWIDTH = 32,
  parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
  // inputs
  input logic clk,
  input logic rst,
  input logic [AWIDTH-1:0] addr_i,
  input logic [DWIDTH-1:0] data_i,
  input logic read_en_i,
  input logic write_en_i,
  input logic [2:0] funct3_i,
  // outputs
  output logic [DWIDTH-1:0] data_o
);

    // Increase memory size to 1MB to support full address range
    localparam int MEM_BYTES = 1024 * 1024;  // 1MB total memory

    logic [DWIDTH-1:0] temp_memory [0:`LINE_COUNT - 1];
    logic [7:0] main_memory [0:MEM_BYTES - 1];
    logic [AWIDTH-1:0] address;
    logic [AWIDTH-1:0] effective_addr;
    
    // If address is less than BASE_ADDR, treat it as an offset from BASE_ADDR
    // Otherwise, use it as-is (absolute address)
    assign effective_addr = (addr_i < BASE_ADDR) ? (BASE_ADDR + addr_i) : addr_i;
    assign address = (addr_i == 32'h40000000) ? 32'h00000000 : effective_addr - BASE_ADDR;
    int i;
 
    initial begin
        for (i = 0; i < MEM_BYTES; i++) begin
            main_memory[i] = 8'h00;
        end
        
        $readmemh(`MEM_PATH, temp_memory);
        for (i = 0; i < `LINE_COUNT; i++) begin
            main_memory[4*i]     = temp_memory[i][7:0];
            main_memory[4*i + 1] = temp_memory[i][15:8];
            main_memory[4*i + 2] = temp_memory[i][23:16];
            main_memory[4*i + 3] = temp_memory[i][31:24];
        end
        $display("MEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
        $display("MEMORY: Total memory size: %0d bytes (%0d KB)", MEM_BYTES, MEM_BYTES/1024);
        $display("MEMORY: Program size: %0d bytes, Remaining: %0d bytes", 
                 `LINE_COUNT * 4, MEM_BYTES - (`LINE_COUNT * 4));
    end

    // Read logic with size and sign extension support
    always_comb begin
        data_o = '0;
        if (read_en_i) begin
            // Ignore reads to address 0
            if (addr_i == 32'h00000000) begin
                data_o = '0;
            end else if ($isunknown(addr_i)) begin
                data_o = '0;
            end else if ((effective_addr >= BASE_ADDR) && (effective_addr < (BASE_ADDR + MEM_BYTES))) begin
                // Check if the full access fits within bounds
                if ((funct3_i == FUNCT3_LB || funct3_i == FUNCT3_LBU) && (address < MEM_BYTES)) begin
                    // Byte access
                    if (funct3_i == FUNCT3_LB)
                        data_o = {{24{main_memory[address][7]}}, main_memory[address]};
                    else
                        data_o = {24'b0, main_memory[address]};
                end else if ((funct3_i == FUNCT3_LH || funct3_i == FUNCT3_LHU) && (address + 1 < MEM_BYTES)) begin
                    // Halfword access
                    if (funct3_i == FUNCT3_LH)
                        data_o = {{16{main_memory[address + 1][7]}}, main_memory[address + 1], main_memory[address]};
                    else
                        data_o = {16'b0, main_memory[address + 1], main_memory[address]};
                end else if ((funct3_i == FUNCT3_LW) && (address + 3 < MEM_BYTES)) begin
                    // Word access
                    data_o = {main_memory[address + 3], main_memory[address + 2], main_memory[address + 1], main_memory[address]};
                end else if ((address + 3 < MEM_BYTES) && (funct3_i != FUNCT3_LB) && (funct3_i != FUNCT3_LBU) && (funct3_i != FUNCT3_LH) && (funct3_i != FUNCT3_LHU) && (funct3_i != FUNCT3_LW)) begin
                    // Default to word access for unknown funct3
                    data_o = {main_memory[address + 3], main_memory[address + 2], main_memory[address + 1], main_memory[address]};
                end else begin
                    data_o = '0;
                end
            end else begin
                data_o = '0;
            end
        end
    end
    
    // Write logic with size support
    always_ff @(posedge clk) begin
        if (write_en_i) begin
            if (addr_i == 32'h00000000) begin
                // Do nothing
            end else if ((effective_addr >= BASE_ADDR) && (effective_addr < (BASE_ADDR + MEM_BYTES))) begin
                if ((funct3_i == FUNCT3_SB) && (address < MEM_BYTES)) begin
                    main_memory[address] <= data_i[7:0];
                    $display("MEMORY: Wrote byte 0x%02h to 0x%08h", data_i[7:0], effective_addr);
                end else if ((funct3_i == FUNCT3_SH) && (address + 1 < MEM_BYTES)) begin
                    main_memory[address] <= data_i[7:0];
                    main_memory[address + 1] <= data_i[15:8];
                    $display("MEMORY: Wrote halfword 0x%04h to 0x%08h", data_i[15:0], effective_addr);
                end else if ((funct3_i == FUNCT3_SW) && (address + 3 < MEM_BYTES)) begin
                    main_memory[address] <= data_i[7:0];
                    main_memory[address + 1] <= data_i[15:8];
                    main_memory[address + 2] <= data_i[23:16];
                    main_memory[address + 3] <= data_i[31:24];
                    $display("MEMORY: Wrote word 0x%08h to 0x%08h", data_i, effective_addr);
                end else if ((address + 3 < MEM_BYTES) && (funct3_i != FUNCT3_SB) && (funct3_i != FUNCT3_SH) && (funct3_i != FUNCT3_SW)) begin
                    main_memory[address] <= data_i[7:0];
                    main_memory[address + 1] <= data_i[15:8];
                    main_memory[address + 2] <= data_i[23:16];
                    main_memory[address + 3] <= data_i[31:24];
                    $display("MEMORY: Wrote word 0x%08h to 0x%08h", data_i, effective_addr);
                end else begin
                    $display("MEMORY: OOB write @0x%08h", effective_addr);
                end
            end else begin
                $display("MEMORY: OOB write @0x%08h", effective_addr);
            end
        end
    end
 
endmodule : memory