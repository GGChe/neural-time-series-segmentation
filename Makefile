# ============================================================
# Cocotb configuration
# ============================================================

export CXX = g++
export CC = gcc
export COCOTB_WAVES = 1
export COCOTB_WAVE_FORMAT = fst

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

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

.PHONY: test-cocotb test-rtl view-cocotb view-rtl clean

# Run Cocotb testbench
test-cocotb: test-detectors

test-detectors:
	cd $(COCOTB_DIR) && poetry run $(MAKE) SIM=$(SIM) TOPLEVEL=detectors_wrapper MODULE=test_detectors

test-all: test-detectors

# Run RTL testbench (Icarus)
test-rtl:
	@echo "Compiling verilog sources..."
	@# Copy data file for simulation
	cp $(TEST_FILES_DIR)/20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt .
	iverilog -o detectors_tb $(VERILOG_SOURCES) $(TB_DIR)/detectors_tb.v
	vvp detectors_tb
	@rm 20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt

# Run Classifier testbench (Icarus)
test-classifier:
	@echo "Compiling verilog sources..."
	@# Copy data file for simulation
	cp $(TEST_FILES_DIR)/20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt .
	iverilog -o classifier_tb $(VERILOG_SOURCES) $(TB_DIR)/classifier_tb.v
	vvp classifier_tb
	@rm 20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt

# View Cocotb waveforms
view-cocotb:
	gtkwave $(COCOTB_DIR)/dump.fst

# View RTL testbench waveforms
view-rtl:
	gtkwave tb/verilog/wave.gtkw

# compile tests for verilog and view
rtl: test-rtl view-rtl

clean::
	rm -rf sim_build __pycache__ .pytest_cache
	rm -f results.xml *.csv *.html *.vcd *.fst *.ghw *.cf *.o $(RTL_TB) classifier_tb detectors_tb
	cd $(COCOTB_DIR) && rm -rf sim_build __pycache__ results.xml *.csv *.html *.fst
