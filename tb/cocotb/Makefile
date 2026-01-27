SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PWD=$(shell pwd)
PROJ_DIR=$(PWD)/../..
SRC_DIR=$(PROJ_DIR)/src

# All Verilog Sources
VERILOG_SOURCES = $(shell find $(SRC_DIR) -name "*.v")

TOPLEVEL ?= detectors_wrapper
MODULE ?= test_detectors

include $(shell cocotb-config --makefiles)/Makefile.sim
