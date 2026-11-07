###############################################################################
# Variables: Program ELF
###############################################################################
ELF_FILE ?= test.elf

OBJCOPY ?= $(shell which riscv64-unknown-elf-objcopy 2>/dev/null || which riscv32-unknown-elf-objcopy 2>/dev/null || which riscv-none-elf-objcopy 2>/dev/null)
ifeq ($(OBJCOPY),)
  ${error RISC-V objcopy tool missing from PATH. Set OBJCOPY or add /mingw64/opt/riscv/bin to PATH}
endif
ifeq ($(shell which iverilog),)
  ${error iverilog missing from PATH - Icarus Verilog required}
endif


###############################################################################
# Variables: Defaults
###############################################################################
TRACE          ?= 1

SRC_V_DIR      ?= ../../src/core .
SRC_DIR        ?= .

EXE            ?= output.out

###############################################################################
# Variables: Verilog
###############################################################################
SRC_V       ?= $(filter-out %postsyn.v, $(foreach src,$(SRC_V_DIR),$(wildcard $(src)/*.v)))
SRC_SV       ?= $(foreach src,$(SRC_V_DIR),$(wildcard $(src)/*.sv))

VFLAGS      += $(patsubst %,-I%,$(SRC_V_DIR))
VFLAGS      += -DTRACE=$(TRACE)
VFLAGS      += -Dverilog_sim

###############################################################################
# Variables: Lists of objects, source and deps
###############################################################################
BUILD_DIR      ?= build/

ifneq ($(findstring bubblesort,$(ELF_FILE)),)
  SAV_PROFILE := gtksettings_bubblesort.sav
else ifneq ($(findstring quicksort,$(ELF_FILE)),)
  SAV_PROFILE := gtksettings_quicksort.sav
else ifneq ($(findstring dotproduct,$(ELF_FILE))$(findstring dot_product,$(ELF_FILE)),)
  SAV_PROFILE := gtksettings_dotproduct.sav
else ifneq ($(findstring arraysum_mul,$(ELF_FILE))$(findstring array_sum_mul,$(ELF_FILE)),)
  SAV_PROFILE := gtksettings_arraysum_mul.sav
else ifneq ($(findstring swapbits,$(ELF_FILE))$(findstring swap_bits,$(ELF_FILE)),)
  SAV_PROFILE := gtksettings_swapbits.sav
else
  SAV_PROFILE := gtksettings_all.sav
endif

SAV_FILE       ?= gtksettings.sav

###############################################################################
# Rules
###############################################################################
all: run

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/tcm.bin: $(ELF_FILE) | $(BUILD_DIR)
	$(OBJCOPY) $< -O binary $@

$(BUILD_DIR)/$(EXE): $(SRC_V) $(SRC_SV) | $(BUILD_DIR)
	@echo "# Compiling verilog"
	iverilog $(VFLAGS) -o $@ $(SRC_V) $(SRC_SV)

run: $(BUILD_DIR)/$(EXE) $(BUILD_DIR)/tcm.bin
	@cp -f $(SAV_PROFILE) gtksettings.sav
	@echo "# Active GTKWave layout: $(SAV_PROFILE) -> gtksettings.sav"
	vvp $(BUILD_DIR)/$(EXE) -vcd

view:
	gtkwave waveform.vcd $(SAV_FILE)

clean:
	rm -rf $(BUILD_DIR) *.vcd

.PHONY: all run view clean $(BUILD_DIR)/tcm.bin

