# To Run The Testbenches Follow These Instructions
## Terminal: start vsim UI first
```vsim -gui```

## Create work library
```vlib work```

## Compile design files
```
vlog -suppress 7061 \
     +define+MEM_DEPTH=127 \
     +define+LINE_COUNT=127 \
     +define+MEM_PATH=\"mem_init.hex\" \
     memory.sv memory_tb.sv fetch.sv fetch_tb.sv
```

## Start simulation
```vsim -voptargs=+acc "testbench file name"```

## Add waves
```add wave -r /*```

## Run simulation
```run -all```