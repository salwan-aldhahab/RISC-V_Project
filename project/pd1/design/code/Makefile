# Makefile for compiling and running memory_tb with ModelSim

# Source files
SRC = memory.sv memory_tb.sv

# Hex file
HEX = init.hex

# Macros (adjust as needed)
DEFINES = +define+MEM_DEPTH=127 \
          +define+LINE_COUNT=127 \
          +define+MEM_PATH=\"$(HEX)\"

VLOG_FLAGS = -suppress 7061

all: run

# Compile only
compile:
	vlib work
	vlog $(VLOG_FLAGS) $(DEFINES) $(SRC)

# Run in console (no GUI)
run: compile
	vsim -c work.memory_tb -do "run -all; quit"

# Run in GUI with waveform viewer
gui: compile
	vsim work.memory_tb -do "run -all"

# Clean generated files
clean:
	rm -rf work transcript vsim.wlf
