# PD5 Technical Documentation

This folder contains the LaTeX technical report for **PD5** — the final, complete
deliverable of the RISC-V project: a fully-pipelined, five-stage, in-order RV32I core
implemented in SystemVerilog, verified under ModelSim (Intel FPGA / Quartus) against the
`rv32-bmarks` benchmark suite.

## Contents

- `main.tex` — the full technical report (single self-contained source).
- `README.md` — this file.

## What the report covers

- RV32I background and the five-stage pipeline / hazard taxonomy
- Top-level architecture with a TikZ datapath diagram
- Per-module implementation (fetch, decode/igen/control, register file, ALU/branch control,
  memory, writeback) with interface tables
- Pipeline registers and the NOP-injection flush/stall mechanism
- **Hazard handling** — MX/WX forwarding (with a TikZ forwarding diagram), load–use and
  write–decode stalls, branch/jump flushes, and store-data (WM) forwarding
- Verification methodology (ModelSim/Verilator, gtkwave, bash + Make, probes and pattern
  checks) and the three-level test hierarchy
- Results (all 64 tests pass) and appendices (file inventory, probes, benchmark list)

## Building the PDF

You need a standard TeX distribution with TikZ (**MiKTeX** or **TeX Live**). No `bibtex`
pass is required — references use an inline `thebibliography` environment.

Run LaTeX **twice** so the table of contents and cross-references resolve:

```bash
pdflatex main.tex
pdflatex main.tex
```

Or, if `latexmk` is available (recommended — it handles the repeat passes automatically):

```bash
latexmk -pdf main.tex
```

Either produces `main.pdf` in this folder.

### No local LaTeX?

Upload `main.tex` to [Overleaf](https://www.overleaf.com) (New Project → Upload Project, or
paste the file) and it will compile in the browser with no local installation.
