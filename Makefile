# ============================================================
# Cocotb configuration
# ============================================================

export CXX = g++
export CC = gcc
export COCOTB_WAVES = 1
export COCOTB_WAVE_FORMAT = fst

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

# Enable FST tracing for Verilator
EXTRA_ARGS += --trace --trace-fst --trace-structs

export PYTHONPATH := $(PWD)/tb/cocotb:$(PYTHONPATH)
export PLUSARGS += +trace

# Paths
SRC_DIR = $(PWD)/src
TB_DIR = $(PWD)/tb/verilog
COCOTB_DIR = $(PWD)/tb/cocotb
TEST_FILES_DIR = $(PWD)/test_files

# verilog source files
VERILOG_SOURCES = $(shell find $(SRC_DIR) -name "*.v")
TB_SOURCES = $(shell find $(TB_DIR) -name "*.v")

# Testbench entity
RTL_TB = detectors_tb


.PHONY: help test-cocotb test-rtl view-cocotb view-rtl clean setup librelane view-openroad

# Help target: lists all targets with descriptions (marked with #)
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'



# Run Cocotb testbench
test-cocotb: test-detectors  ## Run Cocotb testbench

test-detectors:
	cd $(COCOTB_DIR) && poetry run $(MAKE) SIM=$(SIM) TOPLEVEL=detectors_wrapper MODULE=test_detectors

test-all: test-detectors



# Install dependencies
setup:  ## Install dependencies
	poetry install



# Run RTL testbench (Icarus)
test-rtl:  ## Run RTL testbench (Icarus)
	@echo "Compiling verilog sources..."
	@# Copy data file for simulation
	cp $(TEST_FILES_DIR)/20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt .
	iverilog -o detectors_tb $(VERILOG_SOURCES) $(TB_DIR)/detectors_tb.v
	vvp detectors_tb
	@rm 20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt

# Run Classifier testbench (Icarus)
test-classifier:  ## Run Classifier testbench (Icarus)
	@echo "Compiling verilog sources..."
	@# Copy data file for simulation
	cp $(TEST_FILES_DIR)/20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt .
	iverilog -o classifier_tb $(VERILOG_SOURCES) $(TB_DIR)/classifier_tb.v
	vvp classifier_tb
	@rm 20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt



# View Cocotb waveforms
view-cocotb:  ## View Cocotb waveforms
	LC_ALL=C gtkwave --script $(COCOTB_DIR)/signals.tcl $(COCOTB_DIR)/dump.fst



# View RTL testbench waveforms
view-rtl:  ## View RTL testbench waveforms
	LC_ALL=C gtkwave tb/verilog/wave.gtkw



# Run full LibreLane flow
librelane:  ## Run full LibreLane flow
	cd librelane && librelane config.json --flow classic



# View synthesized/routed model in OpenROAD
view-openroad:  ## View synthesized/routed model in OpenROAD
	@echo "Finding latest run..."
	@LATEST_RUN=$$(ls -td librelane/runs/RUN_* 2>/dev/null | head -n 1); \
	if [ -z "$$LATEST_RUN" ]; then \
		echo "No runs found in librelane/runs/"; \
		exit 1; \
	fi; \
	echo "Using run: $$LATEST_RUN"; \
	LATEST_ODB=$$(find $$LATEST_RUN -name "*.odb" | sort | tail -n 1); \
	if [ -z "$$LATEST_ODB" ]; then \
		echo "No .odb files found in $$LATEST_RUN"; \
		exit 1; \
	fi; \
	echo "Opening $$LATEST_ODB in OpenROAD..."; \
	echo "read_db $$LATEST_ODB" > view.tcl; \
	openroad -gui view.tcl; \
	rm view.tcl



# compile tests for verilog and view
rtl: test-rtl view-rtl

clean::
	rm -rf sim_build __pycache__ .pytest_cache
	rm -f results.xml *.csv *.html *.vcd *.fst *.ghw *.cf *.o $(RTL_TB) classifier_tb detectors_tb
	cd $(COCOTB_DIR) && rm -rf sim_build __pycache__ results.xml *.csv *.html *.fst
