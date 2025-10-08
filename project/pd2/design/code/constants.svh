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

parameter logic [6:0] OPCODE_RTYPE  = 7'b0110011;
parameter logic [6:0] OPCODE_ITYPE  = 7'b0010011;
parameter logic [6:0] OPCODE_LOAD   = 7'b0000011;
parameter logic [6:0] OPCODE_STORE  = 7'b0100011;
parameter logic [6:0] OPCODE_BRANCH = 7'b1100011;
parameter logic [6:0] OPCODE_JALR   = 7'b1100111;
parameter logic [6:0] OPCODE_JAL    = 7'b1101111;
parameter logic [6:0] OPCODE_LUI    = 7'b0110111;
parameter logic [6:0] OPCODE_AUIPC  = 7'b0010111;
`endif
