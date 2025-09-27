# To Run The Testbenches Follow These Instructions
1- Terminal: start vsim UI first
```vsim -gui```

2- Create work library
```vlib work```

3- Compile design files
```
vlog -suppress 7061 \
     +define+MEM_DEPTH=127 \
     +define+LINE_COUNT=127 \
     +define+MEM_PATH=\"mem_init.hex\" \
     memory.sv memory_tb.sv fetch.sv fetch_tb.sv
```

4- Start simulation
```vsim -voptargs=+acc "testbench file name"```

5- Add waves
```add wave -r /*```

6- Run simulation
```run -all```