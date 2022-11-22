SHELL := /bin/bash

# Directory variables
CUR_DIR := $(PWD)
$(info CUR_DIR=$(CUR_DIR))
SCRIPTS_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
$(info SCRIPTS_DIR=$(SCRIPTS_DIR))
ROOT_DIR := $(shell dirname $(SCRIPTS_DIR))
$(info ROOT_DIR=$(ROOT_DIR))

EDK2_SRC_DIR := $(SCRIPTS_DIR)/edk2
EDK2_NON_OSI_SRC_DIR := $(SCRIPTS_DIR)/edk2-non-osi
EDK2_PLATFORMS_SRC_DIR := $(SCRIPTS_DIR)/edk2-platforms
REQUIRE_EDK2_SRC := $(EDK2_SRC_DIR) $(EDK2_PLATFORMS_SRC_DIR) $(EDK2_NON_OSI_SRC_DIR)

IASL_DIR := $(SCRIPTS_DIR)/toolchain/iasl
COMPILER_DIR := $(SCRIPTS_DIR)/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu
AARCH64_TOOLS_DIR := $(COMPILER_DIR)/bin

# Compiler variables
DEVEL_MODE ?= TRUE
EDK2_GCC_TAG := GCC5
GCC5_AARCH64_PREFIX := aarch64-linux-gnu-
CROSS_COMPILE := $(AARCH64_TOOLS_DIR)/$(GCC5_AARCH64_PREFIX)
$(info CROSS_COMPILE=$(CROSS_COMPILE))
COMPILER := $(AARCH64_TOOLS_DIR)/$(GCC5_AARCH64_PREFIX)

NUM_THREADS := $(shell echo $$(( $(shell getconf _NPROCESSORS_ONLN) + $(shell getconf _NPROCESSORS_ONLN))))

# Tools variables
IASL := iasl
EXECUTABLES := openssl git cut sed awk wget tar flex bison gcc g++ python3

# Build variant variables
BUILD_VARIANT := $(if $(shell echo $(DEBUG) | grep -w 1),DEBUG,RELEASE)
BUILD_VARIANT_LOWER := $(shell echo $(BUILD_VARIANT) | tr A-Z a-z)
BUILD_VARIANT_UFL := $(shell echo $(BUILD_VARIANT_LOWER) | sed 's/.*/\u&/')

# iASL version
IASL_VER := 20200110

# File path variables
OUTPUT_VARIANT := $(if $(shell echo $(DEBUG) | grep -w 1),_debug,release)
# OUTPUT_BASENAME = $(BOARD_NAME)_tianocore_$(OUTPUT_VARIANT)_$(VER).$(BUILD)
OUTPUT_BASENAME = $(OUTPUT_VARIANT)
$(eval RELEASE_SUBDIR_ := $(subst .A1,,$(OUTPUT_BASENAME)))
$(eval RELEASE_SUBDIR := $(subst _tianocore_atf,,$(RELEASE_SUBDIR_)))

OUTPUT_BIN_DIR := $(if $(DEST_DIR),$(DEST_DIR),$(CUR_DIR)/BUILDS/$(OUTPUT_BASENAME))
#OUTPUT_FD_IMAGE := $(OUTPUT_BIN_DIR)/tianocore$(OUTPUT_VARIANT)_$(VER).$(BUILD).fd
OUTPUT_FD_IMAGE := $(OUTPUT_BIN_DIR)/RPI_EFI.fd


.PHONY: all
all: tianocore_fd

## clean			: Clean basetool and tianocore build
.PHONY: clean
clean:
	@echo "Tianocore clean BaseTools..."
	$(MAKE) -C $(EDK2_SRC_DIR)/BaseTools clean

	@echo "Tianocore clean $(CUR_DIR)/Build..."
	@rm -fr $(CUR_DIR)/Build

	@echo "Ampere Tools clean $(CUR_DIR)/edk2-ampere-tools/toolchain..."
	@rm -fr $(CUR_DIR)/toolchain


_tianocore_prepare: _check_source _check_tools _check_compiler _check_iasl
	$(if $(wildcard $(EDK2_SRC_DIR)/BaseTools/Source/C/bin),,$(MAKE) -C $(EDK2_SRC_DIR)/BaseTools -j $(NUM_THREADS))
	$(eval export WORKSPACE := $(CUR_DIR))
	$(eval export PACKAGES_PATH := $(shell echo $(REQUIRE_EDK2_SRC) | sed 's/ /:/g'))
	$(eval export $(EDK2_GCC_TAG)_AARCH64_PREFIX := $(CROSS_COMPILE))
	$(eval EDK2_FV_DIR := $(WORKSPACE)/Build/RPi4/$(BUILD_VARIANT)_$(EDK2_GCC_TAG)/FV)


_check_source:
	@echo "Checking source...OK"
	$(foreach iter,$(REQUIRE_EDK2_SRC),\
		$(if $(wildcard $(iter)),,$(error "$(iter) not found")))

_check_tools:
	@echo "Checking tools...OK"
	$(foreach iter,$(EXECUTABLES),\
		$(if $(shell which $(iter) 2>/dev/null),,$(error "No $(iter) in PATH")))

_check_compiler:
	@echo "Checking compiler...OK"
# Changes of commit "Remove auto downloading Ampere toolchain b6f7e223" >>>
#ifeq ("$(shell uname -m)", "x86_64")
#	$(if $(shell $(CROSS_COMPILE)gcc -dumpmachine | grep aarch64),,$(error "CROSS_COMPILE is invalid"))
#endif

#	@echo "---> $$($(CROSS_COMPILE)gcc -dumpmachine) $$($(CROSS_COMPILE)gcc -dumpversion)";
# Changes of commit "Remove auto downloading Ampere toolchain b6f7e223" <<<

#Keep the original auto-downloading mechanism >>>
#	$(eval COMPILER_NAME := ampere-8.3.0-20191025-dynamic-nosysroot-crosstools.tar.xz)
#	$(eval COMPILER_URL := https://cdn.amperecomputing.com/tools/compilers/cross/8.3.0/$(COMPILER_NAME))
	$(eval COMPILER_NAME := gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz)
	$(eval COMPILER_URL := https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/$(COMPILER_NAME))
#	https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz

	@if [ -f $(COMPILER)gcc ]; then \
		echo $$($(COMPILER)gcc -dumpmachine) $$($(COMPILER)gcc -dumpversion); \
	else \
		echo -e "Not Found\nDownloading and setting compiler..."; \
		rm -rf $(COMPILER_DIR) && mkdir -p $(COMPILER_DIR); \
		wget -O - -q $(COMPILER_URL) --no-check-certificate | tar xJf - -C $(COMPILER_DIR) --strip-components=1 --checkpoint=.100; \
	fi

_check_iasl:
	@echo -n "Checking iasl..."
	$(eval IASL_NAME := acpica-unix2-$(IASL_VER))
	$(eval IASL_URL := "https://acpica.org/sites/acpica/files/$(IASL_NAME).tar.gz")
ifneq ($(shell $(IASL) -v 2>/dev/null | grep $(IASL_VER)),)
# iASL compiler is already available in the system.
	@echo "OK"
else
# iASL compiler not found or its version is not compatible.
	$(eval export PATH := $(IASL_DIR):$(PATH))

	@if $(IASL) -v 2>/dev/null | grep $(IASL_VER); then \
		echo "OK"; \
	else \
		echo -e "Not Found\nDownloadcleaning and building iasl..."; \
		rm -rf $(IASL_DIR) && mkdir -p $(IASL_DIR); \
		wget -O - -q $(IASL_URL) | tar xzf - -C $(SCRIPTS_DIR) --checkpoint=.100; \
		$(MAKE) -C $(SCRIPTS_DIR)/$(IASL_NAME) -j $(NUM_THREADS) HOST=_CYGWIN; \
		cp $(SCRIPTS_DIR)/$(IASL_NAME)/generate/unix/bin/iasl $(IASL_DIR)/$(IASL); \
		rm -fr $(SCRIPTS_DIR)/$(IASL_NAME); \
	fi
endif

## tianocore_fd		: Tianocore FD image
.PHONY: tianocore_fd
tianocore_fd: _tianocore_prepare
	@echo "Build Tianocore $(BUILD_VARIANT_UFL) FD..."
	$(eval DSC_FILE := $(SCRIPTS_DIR)/my-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc)

	$(eval EDK2_FD_IMAGE := $(EDK2_FV_DIR)/RPI_EFI.fd)
	. $(EDK2_SRC_DIR)/edksetup.sh && build -a AARCH64 -t $(EDK2_GCC_TAG) -b $(BUILD_VARIANT) -n $(NUM_THREADS) \
		-D DEVEL_MODE=$(DEVEL_MODE) \
		-p $(DSC_FILE)
	@mkdir -p $(OUTPUT_BIN_DIR)
	@cp -f $(EDK2_FD_IMAGE) $(OUTPUT_FD_IMAGE)
