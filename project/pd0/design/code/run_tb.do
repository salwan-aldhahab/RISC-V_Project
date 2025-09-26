# ModelSim/Questa run script for pd0_tb
# Compile (SystemVerilog)
vlib work
vlog -sv +acc +incdir+. constants_pkg.sv alu.sv reg_rst.sv three_stage_pipeline.sv pd0_tb.sv

# Simulate with full signal access (needed for wave)
vsim -voptargs=+acc pd0_tb

# Log and add all signals to the waveform
log -r /*
add wave -r /*

# Run for enough time
run -all
