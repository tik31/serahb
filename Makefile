# Project configuration
include make/config.make

# Build configuration
JOBS ?= 4
BUILD_DIR = build
SIM_DIR = sim
SYN_DIR = syn
CURRENT_DIR := $(CURDIR)

LIBS = grlib techmap gaisler lfast_comps irz  


TB_LIBS = testbench spi
#tb_uart tb_jtag testbench

# Main targets
all: syn_source precomp_libs $(addprefix lib-,$(LIBS)) $(addprefix tb-,$(TB_LIBS))
	@echo "Build completed successfully"
version: 
	@echo "Generating version..."
#	$(PYTHON_PATH) bin/gen_version.py > src/rtl/bvn_fpga/rtl/version_pkg.vhd
	
	
precomp_libs:
	$(VMAP) -modelsimini $(BUILD_DIR)/modelsim.ini smartfusion2 $(SMARTFUSION2_LIB)

syn_source:
	@echo "Creating file syn_source.tcl"
	@mkdir -p $(BUILD_DIR)/$(SYN_DIR)
	@mkdir -p $(BUILD_DIR)/$(SIM_DIR)
	@[ -f $(BUILD_DIR)/modelsim.ini ] || cp modelsim.ini $(BUILD_DIR)/modelsim.ini
	@truncate -s 0 $(BUILD_DIR)/$(SYN_DIR)/syn_source.tcl

# Parallel library builds
lib-%:
	@echo "Building library $*..."
	@if ! make -j $(JOBS) CURRENT_DIR=$(CURRENT_DIR) -C src/rtl/$*; then \
		echo "Error building library $*"; \
		exit 1; \
	fi
tb-%:
	@echo "Building testbench $*..."
	@if ! make -j $(JOBS) CURRENT_DIR=$(CURRENT_DIR) -C src/tb/$*; then \
		echo "Error building t $*"; \
		exit 1; \
	fi
# Clean targets
clean:
	@echo "Cleaning build artifacts..."
	@rm -f $(BUILD_DIR)/*.touch
	@rm -rf $(BUILD_DIR)/$(SIM_DIR)/*
	@rm -f $(BUILD_DIR)/$(SYN_DIR)/syn_source.tcl
	@rm -f $(BUILD_DIR)/modelsim.ini
	@find src -name "*.touch" -delete



# Формирование списка библитек для VSIM
$(foreach lib, $(LIBS), $(eval VSIM_LIB_DEPS += -L $(lib)))
$(foreach lib, $(TB_LIBS), $(eval VSIM_LIB_DEPS += -L $(lib)))
do:
	echo vsim -modelsimini build/modelsim.ini -t 1ps -L smartfusion2 $(VSIM_LIB_DEPS) testbench.testbench > bin/sim.do

# File list generation
filelist:
	@echo "Generating file list..."
	@echo "# HDL Source Files" > filelist.txt
	@for lib in $(LIBS); do \
		echo "# Library: $$lib" >> filelist.txt; \
		find src/rtl/$$lib/ \( -name "*.v" -o -name "*.vhd" -o -name "*.sv" \) >> filelist.txt; \
	done
	@for tb in $(TB_LIBS); do \
		echo "# Testbench: $$tb" >> filelist.txt; \
		find src/tb/$$tb/ \( -name "*.v" -o -name "*.vhd" -o -name "*.sv" \) >> filelist.txt; \
	done	
	@echo "Generated filelist.txt with $(shell wc -l < filelist.txt) entries"

.PHONY: all clean filelist lib-% tb-%
