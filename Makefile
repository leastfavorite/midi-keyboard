ARM_GCC_ROOT ?= ./armgcc/bin
GNU_PREFIX ?= arm-none-eabi

CC := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-gcc
CXX := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-c++
LD := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-ld
OBJCOPY := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-objcopy
SIZE := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-size

CC := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-gcc
CXX := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-c++
LD := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-ld
OBJCOPY := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-objcopy
SIZE := $(ARM_GCC_ROOT)/$(GNU_PREFIX)-size

# LINKER_SCRIPT := blinky_gcc_nrf52.ld
SDK ?= sdk
SRC ?= src
INCLUDE ?= include

BUILD_DIR ?= build
ARTIFACT_DIR ?= $(BUILD_DIR)/artifacts
DEPS_DIR ?= $(BUILD_DIR)/deps
OBJS_DIR ?= $(BUILD_DIR)/objs

SRC_FILES += \
	$(SDK)/modules/nrfx/mdk/gcc_startup_nrf52840.S \
	$(SDK)/components/libraries/log/src/nrf_log_frontend.c \
	$(SDK)/components/libraries/log/src/nrf_log_str_formatter.c \
	$(SDK)/components/boards/boards.c \
	$(SDK)/components/libraries/util/app_error.c \
	$(SDK)/components/libraries/util/app_error_handler_gcc.c \
	$(SDK)/components/libraries/util/app_error_weak.c \
	$(SDK)/components/libraries/util/app_util_platform.c \
	$(SDK)/components/libraries/util/nrf_assert.c \
	$(SDK)/components/libraries/atomic/nrf_atomic.c \
	$(SDK)/components/libraries/balloc/nrf_balloc.c \
	$(SDK)/external/fprintf/nrf_fprintf.c \
	$(SDK)/external/fprintf/nrf_fprintf_format.c \
	$(SDK)/components/libraries/memobj/nrf_memobj.c \
	$(SDK)/components/libraries/ringbuf/nrf_ringbuf.c \
	$(SDK)/components/libraries/strerror/nrf_strerror.c \
	$(SDK)/modules/nrfx/soc/nrfx_atomic.c \
	$(SDK)/modules/nrfx/mdk/system_nrf52840.c \
	$(wildcard $(SRC)/*.c) \
	$(wildcard $(SRC)/*.cpp) \
	$(wildcard $(SRC)/*.S)

INCLUDE_FOLDERS += \
	$(SDK)/components \
	$(SDK)/modules/nrfx/mdk \
	$(SDK)/components/libraries/strerror \
	$(SDK)/components/toolchain/cmsis/include \
	$(SDK)/components/libraries/util \
	$(SDK)/components/libraries/balloc \
	$(SDK)/components/libraries/ringbuf \
	$(SDK)/modules/nrfx/hal \
	$(SDK)/components/libraries/bsp \
	$(SDK)/components/libraries/log \
	$(SDK)/modules/nrfx \
	$(SDK)/components/libraries/experimental_section_vars \
	$(SDK)/components/libraries/delay \
	$(SDK)/integration/nrfx \
	$(SDK)/components/drivers_nrf/nrf_soc_nosd \
	$(SDK)/components/libraries/atomic \
	$(SDK)/components/boards \
	$(SDK)/components/libraries/memobj \
	$(SDK)/external/fprintf \
	$(SDK)/components/libraries/log/src \
	$(INCLUDE)

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
CFLAGS += -DNRF52840_XXAA
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
ASMFLAGS += -DNRF52840_XXAA
ASMFLAGS += -D__HEAP_SIZE=8192
ASMFLAGS += -D__STACK_SIZE=8192

# Linker flags
LDFLAGS += $(OPT)
LDFLAGS += -mthumb -mabi=aapcs -L$(SDK)/modules/nrfx/mdk -T$(LINKER_SCRIPT)
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
.PHONY: all
all: $(ARTIFACT_DIR)/a.hex $(ARTIFACT_DIR)/a.bin

LINKER_SCRIPT := blinky_gcc_nrf52.ld
include $(shell find $(DEPS_DIR) -name '*.d')
