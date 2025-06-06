# BAW KeyLogger - Linux Kernel Module Makefile
#
# This Makefile is used to compile the keylogger kernel module.
# It uses the kernel build system to properly compile the module
# with the correct headers and flags.

# Name of the kernel module (without .ko extension)
obj-m := keylogger.o

# Get the current kernel version
KERNEL_VERSION := $(shell uname -r)

# Path to kernel headers (adjust if needed)
KERNEL_DIR := /lib/modules/$(KERNEL_VERSION)/build

# Current directory
PWD := $(shell pwd)
BUILD_DIR := $(PWD)/build

# Default target - build the module
all:
	@echo "Building BAW KeyLogger kernel module..."
	@echo "Kernel version: $(KERNEL_VERSION)"
	@echo "Kernel headers: $(KERNEL_DIR)"
	@mkdir -p $(BUILD_DIR)
	@cp keylogger.c $(BUILD_DIR)/
	@echo "obj-m := keylogger.o" > $(BUILD_DIR)/Makefile
	$(MAKE) -C $(KERNEL_DIR) M=$(BUILD_DIR) modules
	@echo "Build complete! Module: $(BUILD_DIR)/keylogger.ko"

# Clean target - remove compiled files
clean:
	@echo "Cleaning build files..."
	@if [ -d "$(BUILD_DIR)" ]; then rm -rf $(BUILD_DIR); fi
	rm -f *.o *.ko *.mod.c *.mod *.order *.symvers

# Install target - load the module (requires root)
install: all
	@echo "Loading keylogger module (requires root privileges)..."
	sudo insmod $(BUILD_DIR)/keylogger.ko
	@echo "Module loaded! Check dmesg for output:"
	dmesg | grep -i keylogger | tail -10

# Uninstall target - unload the module (requires root)
uninstall:
	@echo "Unloading keylogger module (requires root privileges)..."
	sudo rmmod keylogger
	@echo "Module unloaded! Check dmesg for output:"
	dmesg | grep -i keylogger | tail -5

# Status target - check if module is loaded
status:
	@echo "Checking module status..."
	@if lsmod | grep -q keylogger; then \
		echo "✓ KeyLogger module is currently loaded"; \
		lsmod | grep keylogger; \
	else \
		echo "✗ KeyLogger module is not loaded"; \
	fi

# Log target - show recent kernel messages
log:
	@echo "Recent kernel messages from keylogger:"
	dmesg | grep -i keylogger | tail -20

# Help target - show available commands
help:
	@echo "BAW KeyLogger - Available Make targets:"
	@echo ""
	@echo "  make all      - Build the kernel module"
	@echo "  make clean    - Clean build files"
	@echo "  make install  - Build and load the module (requires sudo)"
	@echo "  make uninstall- Unload the module (requires sudo)"
	@echo "  make status   - Check if module is loaded"
	@echo "  make log      - Show recent keylogger kernel messages"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Usage example:"
	@echo "  1. make all          # Build the module"
	@echo "  2. make install      # Load the module"
	@echo "  3. make log          # Watch the logs"
	@echo "  4. make uninstall    # Unload when done"
	@echo ""
	@echo "Note: Loading/unloading kernel modules requires root privileges"

# Phony targets (not actual files)
.PHONY: all clean install uninstall status log help
