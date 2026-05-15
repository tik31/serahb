include ../../../make/config.make
NAME = gaisler

VHD_FILES := \
	misc/misc.vhd \
	misc/ahbram.vhd \
	ambatest/ahbtbp.vhd \
	ambatest/ahbtbm.vhd \
	ambatest/ahbtbs.vhd \
	jtag/jtag.vhd \
	jtag/libjtagcom.vhd \
	jtag/jtagcom.vhd \
	jtag/jtagcom2.vhd \
	jtag/ahbjtag.vhd \
	jtag/jtagtst.vhd

# 	misc/sf2apbslv_wrapper.vhd \
# 	misc/sf2mddr_wrapper.vhd \
# 	misc/sf2ficmst_wrapper.vhd \
# # 	misc/sf2ficslv_wrapper.vhd \

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