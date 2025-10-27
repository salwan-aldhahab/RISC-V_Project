/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

/*
 * Define constants as required...
 */

// Opcodes for various instruction types
parameter logic [6:0] OPCODE_RTYPE  = 7'b0110011;
parameter logic [6:0] OPCODE_ITYPE  = 7'b0010011;
parameter logic [6:0] OPCODE_LOAD   = 7'b0000011;
parameter logic [6:0] OPCODE_STORE  = 7'b0100011;
parameter logic [6:0] OPCODE_BRANCH = 7'b1100011;
parameter logic [6:0] OPCODE_JALR   = 7'b1100111;
parameter logic [6:0] OPCODE_JAL    = 7'b1101111;
parameter logic [6:0] OPCODE_LUI    = 7'b0110111;
parameter logic [6:0] OPCODE_AUIPC  = 7'b0010111;

// funct3 values for various instructions
parameter logic [2:0] FUNCT3_ADD_SUB = 3'b000;
parameter logic [2:0] FUNCT3_SLL     = 3'b001;
parameter logic [2:0] FUNCT3_SLT     = 3'b010;
parameter logic [2:0] FUNCT3_SLTU    = 3'b011;
parameter logic [2:0] FUNCT3_XOR     = 3'b100;
parameter logic [2:0] FUNCT3_OR      = 3'b110;
parameter logic [2:0] FUNCT3_AND     = 3'b111;
parameter logic [2:0] FUNCT3_SRL_SRA = 3'b101;
parameter logic [2:0] FUNCT3_BEQ    = 3'b000;  // branch equal
parameter logic [2:0] FUNCT3_BNE    = 3'b001; // branch not equal
parameter logic [2:0] FUNCT3_BLT    = 3'b100; // branch less than
parameter logic [2:0] FUNCT3_BGE    = 3'b101; // branch greater than or equal
parameter logic [2:0] FUNCT3_BLTU   = 3'b110; // branch less than unsigned
parameter logic [2:0] FUNCT3_BGEU   = 3'b111; // branch greater than or equal unsigned
parameter logic [2:0] FUNCT3_LB    = 3'b000;
parameter logic [2:0] FUNCT3_LH    = 3'b001;
parameter logic [2:0] FUNCT3_LW    = 3'b010;
parameter logic [2:0] FUNCT3_LBU   = 3'b100;
parameter logic [2:0] FUNCT3_LHU   = 3'b101;
parameter logic [2:0] FUNCT3_SB    = 3'b000;
parameter logic [2:0] FUNCT3_SH    = 3'b001;
parameter logic [2:0] FUNCT3_SW    = 3'b010;

// funct7 values for R-type instructions
parameter logic [6:0] FUNCT7_ADD  = 7'b0000000;
parameter logic [6:0] FUNCT7_SUB  = 7'b0100000;
parameter logic [6:0] FUNCT7_SRL  = 7'b0000000;
parameter logic [6:0] FUNCT7_SRA  = 7'b0100000;
parameter logic [6:0] FUNCT7_SLL  = 7'b0000000;
parameter logic [6:0] FUNCT7_SLT  = 7'b0000000;
parameter logic [6:0] FUNCT7_SLTU = 7'b0000000;
parameter logic [6:0] FUNCT7_XOR  = 7'b0000000;
parameter logic [6:0] FUNCT7_OR   = 7'b0000000;
parameter logic [6:0] FUNCT7_AND  = 7'b0000000;

// ALU operation codes
parameter logic [3:0] ALU_ADD  = 4'b0000;
parameter logic [3:0] ALU_SUB  = 4'b0001;
parameter logic [3:0] ALU_AND  = 4'b0010;
parameter logic [3:0] ALU_OR   = 4'b0011;
parameter logic [3:0] ALU_XOR  = 4'b0100;
parameter logic [3:0] ALU_SLL  = 4'b0101;
parameter logic [3:0] ALU_SRL  = 4'b0110;
parameter logic [3:0] ALU_SRA  = 4'b0111;
parameter logic [3:0] ALU_SLT  = 4'b1000;
parameter logic [3:0] ALU_SLTU = 4'b1001;
parameter logic [3:0] ALU_LUI  = 4'b1010;
parameter logic [3:0] ALU_AUIPC= 4'b1011;

`endif
