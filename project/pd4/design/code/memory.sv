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
  input  logic clk,
  input  logic rst,
  input  logic [AWIDTH-1:0] addr_i,
  input  logic [DWIDTH-1:0] data_i,
  input  logic read_en_i,
  input  logic write_en_i,
  input  logic [2:0] funct3_i,
  // outputs
  output logic [DWIDTH-1:0] data_o
);

    // Total memory size (bytes)
    localparam int MEM_BYTES = `MEM_DEPTH;

    logic [DWIDTH-1:0] temp_memory [0:`LINE_COUNT - 1];
    logic [7:0]        main_memory [0:MEM_BYTES - 1];

    // Wrapped byte address into main_memory
    logic [AWIDTH-1:0] address;

    // ------------------------------------------------------------
    // Address mapping + wrap-around
    // ------------------------------------------------------------
    // Map BASE_ADDR region into [0, MEM_BYTES) and wrap with %
    // Any addr < BASE_ADDR is treated as-is and wrapped into memory.
    always_comb begin
        logic [AWIDTH-1:0] addr_mapped;

        if (addr_i >= BASE_ADDR) begin
            addr_mapped = addr_i - BASE_ADDR;
        end else begin
            addr_mapped = addr_i;
        end

        // Wrap into memory window [0, MEM_BYTES)
        address = addr_mapped % MEM_BYTES;
    end

    int i;
 
    initial begin
        // Initialize memory to zero
        for (i = 0; i < MEM_BYTES; i++) begin
            main_memory[i] = 8'h00;
        end
        
        // Load program image as 32-bit words, then unpack into bytes (little-endian)
        $readmemh(`MEM_PATH, temp_memory);
        for (i = 0; i < `LINE_COUNT; i++) begin
            main_memory[4*i + 0] = temp_memory[i][7:0];
            main_memory[4*i + 1] = temp_memory[i][15:8];
            main_memory[4*i + 2] = temp_memory[i][23:16];
            main_memory[4*i + 3] = temp_memory[i][31:24];
        end

        $display("MEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
        $display("MEMORY: Total memory size: %0d bytes (%0d KB)", MEM_BYTES, MEM_BYTES/1024);
        $display("MEMORY: Program size: %0d bytes, Remaining: %0d bytes", 
                 `LINE_COUNT * 4, MEM_BYTES - (`LINE_COUNT * 4));
    end

    // ------------------------------------------------------------
    // READ logic with size + sign/zero extension + wrapping
    // ------------------------------------------------------------
    always_comb begin
        data_o = '0;

        if (read_en_i) begin
            if ($isunknown(addr_i)) begin
                data_o = '0;
            end else begin
                // Fetch bytes with wrap-around
                logic [7:0] b0, b1, b2, b3;
                b0 = main_memory[address % MEM_BYTES];
                b1 = main_memory[(address + 1) % MEM_BYTES];
                b2 = main_memory[(address + 2) % MEM_BYTES];
                b3 = main_memory[(address + 3) % MEM_BYTES];

                case (funct3_i)
                    // LB / LBU: byte
                    FUNCT3_LB:  data_o = {{24{b0[7]}}, b0};          // sign-extend
                    FUNCT3_LBU: data_o = {24'b0, b0};                // zero-extend

                    // LH / LHU: halfword (b1 is high byte)
                    FUNCT3_LH:  data_o = {{16{b1[7]}}, b1, b0};      // sign-extend
                    FUNCT3_LHU: data_o = {16'b0, b1, b0};            // zero-extend

                    // LW: word
                    FUNCT3_LW:  data_o = {b3, b2, b1, b0};

                    // Default: treat as word load
                    default:    data_o = {b3, b2, b1, b0};
                endcase
            end
        end
    end
    
    // ------------------------------------------------------------
    // WRITE logic with size support + wrapping
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (write_en_i) begin
            if (addr_i == 32'h00000000) begin
                // Ignore writes to address 0 as in your original code
            end else begin
                case (funct3_i)
                    // SB: store byte
                    FUNCT3_SB: begin
                        main_memory[address % MEM_BYTES] <= data_i[7:0];
                        $display("MEMORY: Wrote byte 0x%02h to 0x%08h", data_i[7:0], addr_i);
                    end

                    // SH: store halfword
                    FUNCT3_SH: begin
                        main_memory[address % MEM_BYTES]             <= data_i[7:0];
                        main_memory[(address + 1) % MEM_BYTES]       <= data_i[15:8];
                        $display("MEMORY: Wrote halfword 0x%04h to 0x%08h", data_i[15:0], addr_i);
                    end

                    // SW: store word
                    FUNCT3_SW: begin
                        main_memory[address % MEM_BYTES]             <= data_i[7:0];
                        main_memory[(address + 1) % MEM_BYTES]       <= data_i[15:8];
                        main_memory[(address + 2) % MEM_BYTES]       <= data_i[23:16];
                        main_memory[(address + 3) % MEM_BYTES]       <= data_i[31:24];
                        $display("MEMORY: Wrote word 0x%08h to 0x%08h", data_i, addr_i);
                    end

                    // Default: treat as word store
                    default: begin
                        main_memory[address % MEM_BYTES]             <= data_i[7:0];
                        main_memory[(address + 1) % MEM_BYTES]       <= data_i[15:8];
                        main_memory[(address + 2) % MEM_BYTES]       <= data_i[23:16];
                        main_memory[(address + 3) % MEM_BYTES]       <= data_i[31:24];
                        $display("MEMORY: Wrote word 0x%08h to 0x%08h", data_i, addr_i);
                    end
                endcase
            end
        end
    end
 
endmodule : memory