# BAW KeyLogger - Linux Kernel Module Documentation

## Overview

This project implements a Linux kernel module that demonstrates basic keylogging functionality for educational purposes. The module intercepts keyboard interrupts, logs keystrokes, and includes an easter egg that triggers when the Konami Code is entered.

## Features

- **Keystroke Logging**: Captures all keyboard input and logs it to the kernel message buffer
- **Konami Code Detection**: Detects the sequence ↑↑↓↓←→←→ba and outputs a special log message
- **Educational Focus**: Heavily commented code explaining Linux kernel driver concepts

## Technical Architecture

### Kernel Module Basics

A Linux kernel module is a piece of code that can be loaded and unloaded into the kernel at runtime. Our keylogger module:

1. **Registers an interrupt handler** for keyboard IRQ (typically IRQ 1)
2. **Intercepts keyboard scan codes** directly from the keyboard controller
3. **Processes and logs keystrokes** using the kernel's printk() function
4. **Maintains state** for Konami Code detection

### Key Components

#### 1. Interrupt Handling
```c
static irqreturn_t keyboard_irq_handler(int irq, void *dev_id)
```
- Called every time a key is pressed or released
- Reads scan codes from port 0x60 (keyboard data port)
- Filters for key press events (ignores key releases)
- Returns IRQ_NONE to allow normal keyboard processing

#### 2. Scan Code Mapping
```c
static char key_map[128] = { ... }
```
- Converts hardware scan codes to readable characters
- Simplified mapping for common keys (a-z, 0-9, space, etc.)
- Handles special keys by logging their scan codes

#### 3. Konami Code Detection
```c
static void check_konami_code(unsigned char scan_code)
```
- Maintains a state machine tracking progress through the sequence
- Resets on incorrect input but handles overlapping sequences
- Triggers melody playback on completion

#### 4. Easter Egg Display
```c
static void display_konami_ascii_art(void)
```
- Outputs the easter egg to kernel log

## How Linux Kernel Drivers Work

### Driver Lifecycle

1. **Module Loading** (`module_init`)
   - Registers interrupt handlers
   - Initializes data structures
   - Performs hardware setup

2. **Runtime Operation**
   - Responds to hardware interrupts
   - Processes data
   - Logs

3. **Module Unloading** (`module_exit`)
   - Unregisters interrupt handlers
   - Cleans up resources
   - Ensures safe removal

### Interrupt Handling in Linux

Linux uses the following interrupt handling system:

- **Hardware generates interrupt** when key is pressed
- **CPU saves context** and jumps to interrupt handler
- **Kernel calls registered handler** (our function)
- **Handler processes the interrupt**
- **Normal execution resumes**

### Considerations

The following was considered when writing this keylogger:

- **Kernel-specific functions**: printk vs printf, kmalloc/kfree vs malloc/free
- **Limited stack space**: Keep local variables minimal
- **Atomic context**: Interrupt handlers cannot sleep or block

## Setup and Usage

### Prerequisites

1. **Linux system** with kernel headers installed
2. **Root privileges** for loading/unloading modules
3. **Build tools**: gcc, make, kernel development packages

### Installation on Ubuntu/Debian
```bash
sudo apt update
sudo apt install build-essential gcc make linux-headers-$(uname -r)
```

### Building the Module

1. **Clone/download the project**
2. **Navigate to project directory**
3. **Build the module**:
   ```bash
   make all
   ```

### Loading the Module

```bash
# Load the module (requires root)
sudo make install

# Check if loaded successfully
make status

# View kernel messages
make log
```

### Testing the Keylogger

1. **Type some keys** - they should appear in kernel logs
2. **Try the Konami Code**: ↑↑↓↓←→←→ba
3. **Monitor logs**: `dmesg | grep KeyLogger` or `watch 'dmesg | grep KeyLogger | tail -15'`

### Unloading the Module

```bash
# Unload the module
sudo make uninstall

# Verify it's unloaded
make status
```

## Code Structure Explanation

### Key Functions

1. **keylogger_init()**: Module initialization
   - Registers keyboard interrupt handler
   - Sets up initial state

2. **keyboard_irq_handler()**: Main interrupt handler
   - Reads scan codes from keyboard
   - Logs keystrokes
   - Checks for Konami Code

3. **keylogger_exit()**: Module cleanup
   - Unregisters interrupt handler
   - Frees resources

## References

- [Linux Kernel Module Programming Guide](https://tldp.org/LDP/lkmpg/2.6/html/)
- [Linux Device Drivers (O'Reilly)](https://lwn.net/Kernel/LDD3/)
- [Kernel.org Documentation](https://www.kernel.org/doc/)
- [Linux Interrupt Handling](https://www.kernel.org/doc/html/latest/core-api/genericirq.html)
