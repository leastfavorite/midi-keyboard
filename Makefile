ARM_GCC_ROOT ?= $(shell pwd)/armgcc/bin
GNU_PREFIX ?= arm-none-eabi
PROBE ?= /dev/cu.usbmodemJEFF1

CHIP := 52840

CC := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-gcc
DB := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-gdb
CXX := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-c++
OBJCOPY := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-objcopy
SIZE := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-size

SDK ?= sdk
NRFX ?= nrfx
CMSIS ?= CMSIS_5/CMSIS
SRC ?= src
INCLUDE ?= include

LINKER_SCRIPT := $(NRFX)/mdk/nrf$(CHIP)_xxaa.ld

BUILD_DIR ?= build
ARTIFACT_DIR ?= $(BUILD_DIR)/artifacts
DEPS_DIR ?= $(BUILD_DIR)/deps
OBJS_DIR ?= $(BUILD_DIR)/objs

SRC_FILES += \
	$(NRFX)/mdk/gcc_startup_nrf$(CHIP).S \
	$(NRFX)/mdk/system_nrf$(CHIP).c \
	$(wildcard $(SRC)/*.c) \
	$(wildcard $(SRC)/*.cpp) \
	$(wildcard $(SRC)/*.S)

INCLUDE_FOLDERS += \
	$(INCLUDE) \
	$(NRFX)/mdk \
	$(NRFX)/hal \
	$(NRFX)/drivers \
	$(NRFX)/soc \
	$(NRFX) \
	$(NRFX)/templates \
	$(CMSIS)/Core/Include \
	# $(SDK)/components/libraries/util \
	# $(SDK)/components/libraries/delay \
	# $(SDK)/integration/nrfx \
	# $(SDK)/components/drivers_nrf/nrf_soc_nosd \

INC := $(addprefix -I,$(INC_FOLDERS))
#
# # Libraries common to all targets
# LIB_FILES += \
#
# # Optimization flags
OPT = -O3 -g3
# # Uncomment the line below to enable link time optimization
# #OPT += -flto
#
# C flags common to all targets
CFLAGS += $(OPT)
CFLAGS += -DBOARD_PCA10056
CFLAGS += -DBSP_DEFINES_ONLY
CFLAGS += -DCONFIG_GPIO_AS_PINRESET
CFLAGS += -DFLOAT_ABI_HARD
CFLAGS += -DNRF$(CHIP)_XXAA
CFLAGS += -mcpu=cortex-m4
CFLAGS += -mthumb -mabi=aapcs
CFLAGS += -Wall -Werror
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
# keep every function in a separate section, this allows linker to discard unused ones
CFLAGS += -ffunction-sections -fdata-sections -fno-strict-aliasing
CFLAGS += -fno-builtin -fshort-enums
CFLAGS += -D__HEAP_SIZE=8192
CFLAGS += -D__STACK_SIZE=8192

# C++ flags common to all targets
CXXFLAGS += $(OPT)
# Assembler flags common to all targets
ASMFLAGS += -g3
ASMFLAGS += -mcpu=cortex-m4
ASMFLAGS += -mthumb -mabi=aapcs
ASMFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
ASMFLAGS += -DBOARD_PCA10056
ASMFLAGS += -DBSP_DEFINES_ONLY
ASMFLAGS += -DCONFIG_GPIO_AS_PINRESET
ASMFLAGS += -DFLOAT_ABI_HARD
ASMFLAGS += -DNRF$(CHIP)_XXAA
ASMFLAGS += -D__HEAP_SIZE=8192
ASMFLAGS += -D__STACK_SIZE=8192

# Linker flags
LDFLAGS += $(OPT)
LDFLAGS += -mthumb -mabi=aapcs -L$(NRFX)/mdk -T$(LINKER_SCRIPT)
LDFLAGS += -mcpu=cortex-m4
LDFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
# let linker dump unused sections
LDFLAGS += -Wl,--gc-sections
# use newlib in nano version
LDFLAGS += --specs=nano.specs
# LDFLAGS += -nostdlib
# LDFLAGS += -nostartfiles
# # Add standard libraries at the very end of the linker input, after all objects
# # that may need symbols provided by these libraries.
LIB_FILES += -lc -lnosys -lm

DEPFLAGS += $(OPT)
DEPFLAGS += -MM -MF $@ -MP

BUILDFLAGS += $(OPT)
BUILDFLAGS += -c -o $@

ALL_DEPS := $(SRC_FILES:%=$(DEPS_DIR)/%.d)
ALL_OBJS := $(SRC_FILES:%=$(OBJS_DIR)/%.o)
INCLUDES := $(addprefix -I,$(INCLUDE_FOLDERS))

$(DEPS_DIR)/%.c.d: %.c
	mkdir -p $(@D)
	$(CC) -std=c99 $(CFLAGS) $(DEPFLAGS) $(INCLUDES) $<

$(DEPS_DIR)/%.cpp.d: %.cpp
	mkdir -p $(@D)
	$(CXX) $(CFLAGS) $(CXXFLAGS) $(DEPFLAGS) $(INCLUDES) $<

$(DEPS_DIR)/%.S.d: %.S
	mkdir -p $(@D)
	$(CC) -x assembler-with-cpp $(ASMFLAGS) $(DEPFLAGS) $(INCLUDES) $<

$(OBJS_DIR)/%.c.o: %.c $(DEPS_DIR)/%.c.d
	mkdir -p $(@D)
	$(CC) -std=c99 $(CFLAGS) $(BUILDFLAGS) $(INCLUDES) $<

$(OBJS_DIR)/%.cpp.o: %.cpp $(DEPS_DIR)/%.cpp.d
	mkdir -p $(@D)
	$(CC) -x assembler-with-cpp $(ASMFLAGS) $(BUILDFLAGS) $(INCLUDES) $<

$(OBJS_DIR)/%.S.o: %.S $(DEPS_DIR)/%.S.d
	mkdir -p $(@D)
	$(CC) -x assembler-with-cpp $(ASMFLAGS) $(BUILDFLAGS) $(INCLUDES) $<

$(ARTIFACT_DIR)/a.out: $(ALL_OBJS)
	$(info $(ALL_OBJS))
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ $(LIB_FILES) $(INCLUDES) -Wl,-Map=$(@:.out=.map) -o $@

$(ARTIFACT_DIR)/a.hex: $(ARTIFACT_DIR)/a.out
	mkdir -p $(@D)
	$(OBJCOPY) -O ihex $< $@

$(ARTIFACT_DIR)/a.bin: $(ARTIFACT_DIR)/a.out
	mkdir -p $(@D)
	$(OBJCOPY) -O binary $< $@

.DEFAULT_GOAL := all
.PHONY: all clean flash

all: $(ARTIFACT_DIR)/a.hex $(ARTIFACT_DIR)/a.bin

clean:
	rm -rf $(BUILD_DIR)

flash: $(ARTIFACT_DIR)/a.out
	$(DB) -nx --batch \
		-ex 'target extended-remote $(PROBE)' \
		-ex 'monitor swdp_scan' \
		-ex 'attach 1' \
		-ex 'load' \
		-ex 'compare-sections' \
		-ex 'kill' \
		$<

include $(shell find $(DEPS_DIR) -name '*.d')

