# LibreLane Flow for Neural Time Series Segmentation

This directory contains the configuration to run the complete ASIC synthesis flow using LibreLane (OpenLane).

## Prerequisites

### 1. Nix Environment

LibreLane is best run within a Nix shell.

```bash
# Enter nix-shell with LibreLane
nix-shell
```
*Note: Ensure your `shell.nix` or environment provides `librelane`.*

## Usage

### Run Full Flow (Classic)

Execute the complete RTL-to-GDSII flow using the `librelane` CLI from within the `librelane` directory:

```bash
cd librelane
librelane config.json -run-tag v1 --flow classic
```

### Checking the Results

After executing the flow, you can inspect the logs (error.log, warning.log, flow.log) and results in the `runs/` directory.

### Viewing the Layout

To open the final GDSII layout using KLayout (via LibreLane's wrapper):

```bash
librelane --last-run --flow openinklayout config.json
```

## Configuration

The `config.json` file contains design parameters such as:
- **Design Name**: `top_level_module`
- **Clock Period**: 20.0 ns
- **Core Utilization**: 40%
- **Verilog Files**: List of all source files.

## Outputs

Outputs are generated in the `runs/` directory associated with your run tag (e.g., `runs/v1/`):
- **Reports**: `runs/v1/reports/`
- **GDS**: `runs/v1/results/final/gds/top_level_module.gds`
