# CNN Hardware Accelerator

A Verilog implementation of a CNN hardware accelerator that performs the operation:

```
Output = (Σ(xi × hi)) / 9 / K
```

Where:
- `xi` = input data (9 values)
- `hi` = kernel/filter weights (9 values)
- `K` = scale factor
- Division by 9 is optimized using fixed-point reciprocal multiplication

## Architecture

### Modules

1. **cnn_accelerator_Version2.v** - Top-level module integrating all components
2. **controller_Version2.v** - FSM controlling the data pipeline
3. **multiplier.v** - 32-bit sequential shift-add multiplier
4. **MAC.v** - Multiply-Accumulate unit
5. **divide_by_9_Version2.v** - Optimized divider using reciprocal multiplication
6. **divider_Version2.v** - General-purpose sequential divider

### Directory Structure

```
CNN/
├── src/                          # Source files
│   ├── cnn_accelerator_Version2.v
│   ├── controller_Version2.v
│   ├── multiplier.v
│   ├── MAC.v
│   ├── divider_Version2.v
│   └── divide_by_9_Version2.v
├── tb/                           # Testbenches
│   ├── cnn_accelerator_tb_Version2.v
│   ├── multiplier_tb_Version2.v
│   ├── mac_tb_Version2.v
│   └── divider_tb_Version2.v
├── sim_output/                   # Generated during simulation
│   └── waveforms/               # VCD waveform files
├── Makefile                      # Linux/Unix simulation script
├── sim.bat                       # Windows simulation script
└── README.md                     # This file
```

## Prerequisites

### For Simulation

- **Icarus Verilog** - Open source Verilog simulator
  - Windows: https://bleyer.org/icarus/
  - Linux: `sudo apt-get install iverilog`
  - macOS: `brew install icarus-verilog`

- **GTKWave** (Optional) - Waveform viewer
  - Windows: http://gtkwave.sourceforge.net/
  - Linux: `sudo apt-get install gtkwave`
  - macOS: `brew install gtkwave`

## Running Simulations

### Windows

Use the provided batch script:

```batch
# Run CNN accelerator testbench (default)
sim.bat

# Run specific testbench
sim.bat multiplier
sim.bat mac
sim.bat divider
sim.bat cnn

# Run all tests
sim.bat all

# Clean outputs
sim.bat clean

# Show help
sim.bat help
```

### Linux/Unix/macOS

Use the Makefile:

```bash
# Run CNN accelerator testbench (default)
make

# Run specific testbench
make multiplier
make mac
make divider
make cnn_accelerator

# Run all tests
make test_all

# View waveforms (requires GTKWave)
make wave_cnn
make wave_mult
make wave_mac
make wave_div

# Clean outputs
make clean

# Show help
make help
```

## Testbench Details

### CNN Accelerator Testbench

The top-level testbench (`cnn_accelerator_tb_Version2.v`) includes 8 comprehensive test cases:

1. **Test 1**: Uniform inputs (all 1s)
2. **Test 2**: Uniform inputs with scale factor
3. **Test 3**: Mixed positive values
4. **Test 4**: Negative inputs
5. **Test 5**: Mixed positive and negative values
6. **Test 6**: Large values (stress test)
7. **Test 7**: Zero inputs (edge case)
8. **Test 8**: Sparse kernel (some zeros)

### Component Testbenches

- **multiplier_tb_Version2.v** - Tests the 32-bit multiplier
- **mac_tb_Version2.v** - Tests the MAC unit
- **divider_tb_Version2.v** - Tests the general divider

## Simulation Output

After running simulations:
- VCD waveform files are saved to `sim_output/waveforms/`
- Console output shows test results (PASS/FAIL)
- Use GTKWave to view waveforms:
  ```bash
  gtkwave sim_output/waveforms/cnn_accelerator_tb.vcd
  ```

## Parameters

The CNN accelerator is parameterized:

```verilog
parameter WIDTH = 32        // Data width (bits)
parameter ACC_WIDTH = 72    // Accumulator width (bits)
parameter NUM_INPUTS = 9    // Number of input/kernel values
```

## Design Features

- **Pipeline Architecture**: Multi-stage datapath with controller FSM
- **Optimized Division**: Divide-by-9 uses reciprocal multiplication instead of full division
- **Signed Arithmetic**: Full support for signed input data and kernels
- **Parameterizable**: Easy to adjust data widths and input count
- **Comprehensive Testing**: Multiple test cases covering edge cases

## Performance

- **Latency**: ~50-100 clock cycles per computation (depends on multiplier/divider implementation)
- **Throughput**: Sequential processing of 9 MAC operations
- **Area**: Optimized for FPGA implementation with shift-add multiplier

## Future Enhancements

- [ ] Add controller testbench
- [ ] Implement pipelined multiplier for higher throughput
- [ ] Add ready/valid handshaking protocol
- [ ] Support variable-length input arrays
- [ ] Add synthesis constraints (SDC/XDC files)

## License

Educational/Research Project

## Authors

CNN Accelerator Design Team
