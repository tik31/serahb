include ../../../make/config.make
NAME = lfast_comps

VLOG_FILES := \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/instructions.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/acmtable.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/ramblocks.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/instructram.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/debugblk.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/coreabc.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/ram128x8_smartfusion2.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/iram512x9_rtl.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/ram256x16_rtl.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/ram256x8_rtl.v \
    rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core/instructnvm_bb.v \
    rtl/COREABC_C0/COREABC_C0.v \
    rtl/CoreAPB3_C0/CoreAPB3/4.2.100/rtl/vlog/core/coreapb3.v \
    rtl/CoreAPB3_C0/CoreAPB3/4.2.100/rtl/vlog/core/coreapb3_muxptob3.v \
    rtl/CoreAPB3_C0/CoreAPB3/4.2.100/rtl/vlog/core/coreapb3_iaddr_reg.v \
    rtl/CoreAPB3_C0/CoreAPB3_C0.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/CorePCS.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DEC_DATA.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DEC_ERR.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DEC_RD.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DECODER.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENC_D.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENC_FLIP.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENC_K.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENCODER.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/MUX4X1.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/MUX32X1.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/MUX32X6.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/BUF_DATA.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DECODER_CI.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DECODER_CO.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DEC_RD_L.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DEC_RD_U.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/DEC_WA.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENCODER_64B80B.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENCODER_L.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENCODER_N.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/ENCODER_U.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/WORD_ALIGNER_10.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/WORD_ALIGNER_80.v \
    rtl/CorePCS_C0/CorePCS/3.6.103/rtl/vlog/core/RESET_SYNC.v \
    rtl/CorePCS_C0/CorePCS_C0.v \
    rtl/FCCC_C0/FCCC_C0_0/FCCC_C0_FCCC_C0_0_FCCC.v \
    rtl/FCCC_C0/FCCC_C0.v \
    rtl/LiteFast_C0/LiteFast/1.0.5/RTL/LiteFast.v \
    rtl/LiteFast_C0/LiteFast_C0.v \
    rtl/SERDES_IF_C0/SERDES_IF_C0_0/SERDES_IF_C0_SERDES_IF_C0_0_SERDES_IF.v \
    rtl/SERDES_IF_C0/SERDES_IF_C0_0/SERDES_IF_C0_SERDES_IF_C0_0_SERDES_IF_syn.v \
    rtl/SERDES_IF_C0/SERDES_IF_C0.v \
    rtl/top/top.v

all: syn ../../../build/$(NAME).touch

../../../build/$(NAME).touch: $(VLOG_FILES) $(VHD_FILES) | lib
	@echo "Building $(NAME)..."
	@if [ -n "$(VLOG_FILES)" ]; then \
		echo "Compiling Verilog files..."; \
		$(VLOG) -modelsimini $(MSIM_INI) -work $(NAME) \
			+incdir+rtl/COREABC_C0/COREABC_C0_0/rtl/vlog/core \
			$(VLOG_FILES) || exit 1; \
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
