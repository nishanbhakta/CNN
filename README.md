# CNN Hardware Accelerator

A Verilog implementation of a small CNN-style accelerator that computes:

```text
output = (sum(xi * hi)) / 9 / K
```

Where:
- `xi` = a 3x3 image patch flattened into 9 signed values
- `hi` = a 3x3 kernel flattened into 9 signed values
- `K` = scale factor

The hardware uses truncation toward zero for both division stages. The 3x3 sum and the
post-`/9` value stay at the full 72-bit accumulator width until the final result is
reduced back to the 32-bit output.

## Architecture

### Core modules

1. **cnn_accelerator_Version2.v** - 3-stage pipelined top-level datapath and control integration
2. **controller_Version2.v** - FSM for parallel multiply, reduction stages, divide-by-9, and final divide
3. **multiplier.v** - 32x32 signed sequential shift-add multiplier
4. **MAC.v** - standalone 32x32-to-72-bit MAC plus pipeline accumulator helper
5. **divide_by_9_Version2.v** - exact signed divide-by-9 using a constant restoring divider
6. **divider_Version2.v** - parameterized signed restoring divider
7. **uart_tx.v / uart_result_streamer.v** - board-level UART result transmitter

### Project layout

```text
CNN/
|-- docs/
|-- scripts/
|-- sim_output/
|-- src/
|-- tb/
|-- Makefile
|-- sim.bat
`-- README.md
```

## What Matches The Assignment

- Real shift-add multiplier RTL is implemented in [src/multiplier.v](src/multiplier.v)
- Exact divide-by-9 without `/` is implemented in [src/divide_by_9_Version2.v](src/divide_by_9_Version2.v)
- Standalone 32-bit-input, 72-bit-accumulator MAC is implemented in [src/MAC.v](src/MAC.v)
- Signed restoring divider is implemented in [src/divider_Version2.v](src/divider_Version2.v)
- Standalone and top-level simulations pass with Icarus Verilog

The assignment-oriented design discussion, Nexys A7 resource summary, and estimated area/performance tables are in [docs/nexys_a7_design_report.md](docs/nexys_a7_design_report.md).

## Simulation

### Windows

Run the top-level testbench:

```powershell
.\sim.bat cnn
```

Run the CSV-driven top-level testbench with a richer dataset and visible accuracy summary:

```powershell
.\sim.bat cnn_csv
```

Run all component benches:

```powershell
.\sim.bat all
```

Available `sim.bat` targets:

- `cnn` - directed top-level regression
- `cnn_csv` - CSV-driven top-level regression using `tb/data/cnn_complex_vectors.csv`
- `multiplier`, `mac`, `divider`, `div9`, `uart` - individual module benches
- `all` - runs every test target above

### Linux / macOS

```bash
make
make test_all
```

## Image-Driven Flow

You can preprocess a real image into 3x3 windows and run the generated-data simulation in one command:

```powershell
py -3 scripts\run_image_sim.py path\to\image.png --resize 28x28 --kernel "1,0,-1,1,0,-1,1,0,-1" --scale-factor 1
```

This generates:
- grayscale pixel CSV
- patch CSV with pixels, kernel, intermediate math, and expected outputs
- input-window CSV for the Vivado handoff
- metadata JSON describing the image size, kernel, and window counts
- Verilog include file for the generated windows
- golden output feature-map CSV for reference checking
- hardware `output.csv` written by the generated-image testbench
- per-window `output_trace.csv`
- output comparison CSV for quick cross-verification
- compiled simulation output in `sim_output/`

Useful options for the image flow:

- `--limit-windows N` limits how many windows are written to the CSV outputs
- `--verilog-window-limit N` limits how many windows are compiled into the generated Verilog include, and if omitted all emitted windows are simulated
- `--output-dir path\to\dir` changes the generated-data directory
- `--prepare-only` stops after generating `input_windows.csv`, `golden_output.csv`, and the Vivado handoff files

### Vivado Waveform View

If you want the Python step to only prepare the files for Vivado, run:

```powershell
py -3 scripts\run_image_sim.py path\to\image.png --resize 28x28 --prepare-only
```

Then open Vivado and run the generated-image testbench:

```powershell
vivado -mode gui -source vivado/run_generated_image_sim.tcl -tclargs generated_data
```

If you used a custom output directory, pass that directory instead of `generated_data`.

The Vivado script:
- opens or creates a saved Vivado simulation project under `vivado_build/`
- points `cnn_accelerator_tb` at your generated `generated_windows.vh`
- enables `USE_GENERATED_IMAGE_DATA`
- launches behavioral simulation
- adds common top-level and DUT waves
- writes `output.csv` and `output_trace.csv` into the generated-data folder
- runs the Python comparison helper to produce `output_comparison.csv`
- keeps the waveform open in Vivado so you can inspect the hardware trace

## Parameters

```verilog
parameter WIDTH = 32
parameter ACC_WIDTH = 72
parameter NUM_INPUTS = 9
```

## Performance Notes

- Multiplier latency: 32 cycles
- Divide-by-9 latency: 72 cycles
- General divider latency: 32 cycles
- Top-level accelerator latency: roughly 140 cycles per 3x3 patch with the 3-stage parallel datapath
- DSP usage in the chosen arithmetic path: 0 DSP slices

## Next Steps

- Add Vivado synthesis reports for measured LUT/FF/DSP usage
- Add UART receive-side commands so patches and kernels can be loaded from a host PC
- Add an output feature-map writer so image simulations can emit reconstructed output images
