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
 * Description: Byte-addressable memory implementation. Supports both read and write operations.
 * Reads are combinational and writes are performed on the rising clock edge.
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
 */

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

    localparam [2:0] FUNCT3_LB  = 3'b000; // Load/Store Byte 
    localparam [2:0] FUNCT3_LH  = 3'b001; // Load/Store Halfword 
    localparam [2:0] FUNCT3_LW  = 3'b010; // Load/Store Word
    localparam [2:0] FUNCT3_LBU = 3'b100; // Load Byte Unsigned 
    localparam [2:0] FUNCT3_LHU = 3'b101; // Load Halfword Unsigned 
   

    localparam int LINE_COUNT = `LINE_COUNT; 
    localparam int MEM_BYTES = LINE_COUNT * (DWIDTH/8);

    // Temporary memory for initialization
    logic [DWIDTH-1:0] temp_memory [0:LINE_COUNT - 1];

    // Byte-addressable main memory array 
    logic [7:0] main_memory [0:MEM_BYTES - 1];

    logic [AWIDTH-1:0] address;
    // Calculate byte offset from the BASE_ADDR
    assign address = addr_i - BASE_ADDR;

    int i;

    
    initial begin
        
        $readmemh(`MEM_PATH, temp_memory);

        // Load data from temp_memory into main_memory 
        for (i = 0; i < LINE_COUNT; i++) begin
            main_memory[4*i]      = temp_memory[i][7:0];   
            main_memory[4*i + 1]  = temp_memory[i][15:8];
            main_memory[4*i + 2]  = temp_memory[i][23:16];
            main_memory[4*i + 3]  = temp_memory[i][31:24]; 

        $display("MEMORY: Loaded %0d 32-bit words from %s", LINE_COUNT, `MEM_PATH);
    end

   
    always_comb begin
        data_o = '0;

        if (read_en_i) begin
            // Boundary and validity check
            if ((addr_i < BASE_ADDR) || (addr_i + 32'd3 >= BASE_ADDR + MEM_BYTES)) begin
                data_o = 32'hDEAD_BEEF; // Error data for OOB or unknown address
                $display("MEM: OOB read @0x%08h (mapped 0x%08h)", addr_i, address);
            end else begin
                // Read operation based on funct3 (Word, Halfword, Byte)
                case (funct3_i)
                    FUNCT3_LW: begin // Load Word (LW) 
                        
                        data_o = {
                            main_memory[address + 3], 
                            main_memory[address + 2],
                            main_memory[address + 1],
                            main_memory[address]      
                        };
                    end

                    FUNCT3_LH, FUNCT3_LHU: begin // Load Halfword 
                        logic [15:0] halfword;
                        halfword = {main_memory[address + 1], main_memory[address]}; 
                        if (funct3_i == FUNCT3_LHU) begin
                            data_o = {16'h0000, halfword}; // Zero-Extend LHU
                        end else begin // FUNCT3_LH
                            data_o = {{16{halfword[15]}}, halfword}; 
                        end
                    end

                    FUNCT3_LB, FUNCT3_LBU: begin // Load Byte 
                        logic [7:0] byte;
                        byte = main_memory[address];
                        if (funct3_i == FUNCT3_LBU) begin
                            data_o = {24'h000000, byte}; 
                        end else begin // FUNCT3_LB
                            data_o = {{24{byte[7]}}, byte}; 
                        end
                    end

                    default: begin
                        // If funct3 is unrecognized, default to word read 
                        data_o = {
                            main_memory[address + 3], main_memory[address + 2],
                            main_memory[address + 1], main_memory[address]
                        };
                    end
                endcase
            end
        end
    end


    always_ff @(posedge clk) begin
        if (write_en_i) begin
            if ((addr_i < BASE_ADDR) || (addr_i + 32'd3 >= BASE_ADDR + MEM_BYTES)) begin
                $display("MEM: OOB write @0x%08h", addr_i);
            end else begin
                $display("MEM: Wrote 0x%08h to 0x%08h (funct3=0x%01h)", data_i, addr_i, funct3_i);

                // Store operation based on funct3 (Word, Halfword, Byte)
                case (funct3_i)
                    FUNCT3_LW: begin // Store Word (SW)
                        main_memory[address]      <= data_i[7:0];
                        main_memory[address + 1]  <= data_i[15:8];
                        main_memory[address + 2]  <= data_i[23:16];
                        main_memory[address + 3]  <= data_i[31:24];
                    end
                    FUNCT3_LH: begin // Store Halfword (SH)
                        main_memory[address]      <= data_i[7:0];
                        main_memory[address + 1]  <= data_i[15:8];
                    end
                    FUNCT3_LB: begin // Store Byte (SB)
                        main_memory[address]      <= data_i[7:0];
                    end
                    default: begin
                        $display("MEM: Invalid funct3 write 0x%01h @0x%08h", funct3_i, addr_i);
                    end
                endcase
            end
        end
    end

endmodule : memory
