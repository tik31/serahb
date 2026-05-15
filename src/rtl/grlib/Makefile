include ../../../make/config.make
NAME = grlib

VHD_FILES := \
	stdlib/version.vhd \
	stdlib/stdlib.vhd \
	stdlib/config_types.vhd \
	stdlib/config.vhd \
	stdlib/stdio.vhd \
	stdlib/testlib.vhd \
	util/util.vhd \
	amba/amba.vhd \
	amba/devices.vhd \
	amba/defmst.vhd \
	amba/ahbmst.vhd \
	amba/ahbctrl.vhd

all: syn ../../../build/$(NAME).touch 


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

	
syn: 
	@echo "Generating file library $(NAME)..."
	@for vhd in $(VHD_FILES); do \
		echo -e "add_file -vhdl -lib $(NAME) ../src/rtl/$(NAME)/$$vhd" >> ../../../build/syn/syn_source.tcl; \
	done
	@for vrl in $(VLOG_FILES); do \
		echo -e "add_file -verilog -lib $(NAME) ../src/rtl/$(NAME)/$$vrl" >> ../../../build/syn/syn_source.tcl; \
	done
		@for sv in $(SV_FILES); do \
		echo -e "add_file -system_verilog -lib $(NAME) ../src/rtl/$(NAME)/$$sv" >> ../../../build/syn/syn_source.tcl; \
	done
	
lib: ../../../build/sim/$(NAME)/_lib.map

../../../build/sim/$(NAME)/_lib.map:
	@echo "Creating library..."
	$(VLIB) ../../../build/sim/$(NAME)
	$(VMAP) -modelsimini $(MSIM_INI) $(NAME) $(CURRENT_DIR)/build/sim/$(NAME)
	@touch $@

.PHONY: all clean