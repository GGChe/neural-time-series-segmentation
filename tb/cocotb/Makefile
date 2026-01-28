SIM ?= verilator
TOPLEVEL_LANG ?= verilog

EXTRA_ARGS += --trace --trace-fst --trace-structs

PWD=$(shell pwd)
PROJ_DIR=$(PWD)/../..
SRC_DIR=$(PROJ_DIR)/src

# All Verilog Sources
VERILOG_SOURCES = $(shell find $(SRC_DIR) -name "*.v")

TOPLEVEL ?= detectors_wrapper
MODULE ?= test_detectors

include $(shell cocotb-config --makefiles)/Makefile.sim
