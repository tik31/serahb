include ../../../make/config.make
NAME = testbench

VHD_FILES := \
	dut.vhd \
	testbench.vhd

all: ../../../build/$(NAME).touch

../../../build/$(NAME).touch: $(VLOG_FILES) $(VHD_FILES) | lib
	@echo "Building $(NAME)..."
	@if [ -n "$(VLOG_FILES)" ]; then \
		echo "Compiling Verilog files..."; \
		$(VLOG) -modelsimini $(MSIM_INI) -work $(NAME) $(VLOG_FILES) || exit 1; \
	fi
	@if [ -n "$(VHD_FILES)" ]; then \
		echo "Compiling VHDL files..."; \
		$(VCOM) -modelsimini $(MSIM_INI) -work $(NAME) $(VHD_FILES) || exit 1; \
	fi
	@touch $@
	@echo "Build completed successfully"

lib: ../../../build/sim/$(NAME)/_lib.map

../../../build/sim/$(NAME)/_lib.map:
	echo "Creating testbench..."
	$(VLIB) ../../../build/sim/$(NAME)
	$(VMAP) -modelsimini $(MSIM_INI) $(NAME) $(CURRENT_DIR)/build/sim/$(NAME)
	@touch $@
	
.PHONY: all clean