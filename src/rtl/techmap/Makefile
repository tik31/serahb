include ../../../make/config.make
NAME = techmap

VHD_FILES  := \
	gencomp/gencomp.vhd \
	gencomp/netcomp.vhd \
	maps/allmem.vhd \
	maps/regfile_3p.vhd \
	maps/syncfifo_2p.vhd \
	maps/syncram.vhd \
	maps/syncram64.vhd \
	maps/syncram_2p.vhd \
	maps/syncram_dp.vhd \
	maps/syncrambw.vhd \
	maps/syncram128bw.vhd \
	maps/syncram156bw.vhd \
	maps/syncram256bw.vhd \
	inferred/memory_inferred.vhd \
	maps/alltap.vhd \
	maps/tap.vhd \
	smartfusion2/tap_igloo2.vhd
	
all: syn ../../../build/$(NAME).touch 


../../../build/$(NAME).touch: $(VLOG_FILES) $(VHD_FILES) | lib
	@echo "Building $(NAME)..."
	@if [ -n "$(VLOG_FILES)" ]; then \
		echo "Compiling Verilog files..."; \
		$(VLOG) -modelsimini $(MSIM_INI) -work $(NAME) $(VLOG_FILES) || exit 1; \
	fi
	@if [ -n "$(VHD_FILES)" ]; then \
		echo "Compiling VHDL files..."; \
		$(VCOM) -2008 -modelsimini $(MSIM_INI) -work $(NAME) $(VHD_FILES) || exit 1; \
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
