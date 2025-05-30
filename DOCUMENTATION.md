# BAW KeyLogger - Linux Kernel Module Documentation

## Overview

This project implements a Linux kernel module that demonstrates basic keylogging functionality for educational purposes. The module intercepts keyboard interrupts, logs keystrokes, and includes an easter egg that triggers when the famous Konami Code is entered.

## Features

- **Keystroke Logging**: Captures all keyboard input and logs it to the kernel message buffer
- **Konami Code Detection**: Detects the sequence ↑↑↓↓←→←→BA and plays a victory melody
- **PC Speaker Integration**: Uses the system beeper to play sounds
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

#### 4. PC Speaker Control
```c
static void beep(unsigned int frequency, unsigned int duration)
```
- Programs the 8253/8254 timer chip to generate specific frequencies
- Controls the PC speaker through I/O ports 0x61, 0x43, and 0x42
- Plays a victory melody when Konami Code is detected

## How Linux Kernel Drivers Work

### Driver Lifecycle

1. **Module Loading** (`module_init`)
   - Registers interrupt handlers
   - Initializes data structures
   - Performs hardware setup

2. **Runtime Operation**
   - Responds to hardware interrupts
   - Processes data
   - Communicates with user space (via logs)

3. **Module Unloading** (`module_exit`)
   - Unregisters interrupt handlers
   - Cleans up resources
   - Ensures safe removal

### Interrupt Handling in Linux

Linux uses a sophisticated interrupt handling system:

- **Hardware generates interrupt** when key is pressed
- **CPU saves context** and jumps to interrupt handler
- **Kernel calls registered handler** (our function)
- **Handler processes the interrupt** quickly
- **Normal execution resumes**

### Memory Management

Kernel modules operate in kernel space with special considerations:

- **No standard library**: Use kernel-specific functions (printk vs printf)
- **Limited stack space**: Keep local variables minimal
- **Atomic context**: Interrupt handlers cannot sleep or block
- **Memory allocation**: Use kmalloc/kfree instead of malloc/free

### Security Implications

This keylogger demonstrates several important security concepts:

1. **Kernel-level access**: Can intercept all input before user-space applications
2. **Hardware-level interception**: Bypasses software-based security measures
3. **Stealth operation**: Difficult to detect from user space
4. **System stability**: Improper kernel code can crash the entire system

## Setup and Usage

### Prerequisites

1. **Linux system** with kernel headers installed
2. **Root privileges** for loading/unloading modules
3. **Build tools**: gcc, make, kernel development packages

### Installation on Ubuntu/Debian
```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
```

### Installation on CentOS/RHEL/Fedora
```bash
sudo yum groupinstall "Development Tools"
sudo yum install kernel-devel kernel-headers
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
2. **Try the Konami Code**: ↑↑↓↓←→←→BA
3. **Listen for the victory melody** when code is completed
4. **Monitor logs**: `dmesg | grep KeyLogger`

### Unloading the Module

```bash
# Unload the module
sudo make uninstall

# Verify it's unloaded
make status
```

## Code Structure Explanation

### Header Files
- `linux/module.h`: Core module functionality
- `linux/interrupt.h`: Interrupt handling
- `linux/keyboard.h`: Keyboard-specific definitions
- `asm/io.h`: Low-level I/O operations (inb/outb)

### Module Metadata
```c
MODULE_LICENSE("GPL");
MODULE_AUTHOR("BAW Project Team");
MODULE_DESCRIPTION("Educational keylogger with Konami Code easter egg");
```

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

## Educational Value

This project demonstrates several important concepts:

### Linux Kernel Programming
- Module structure and lifecycle
- Interrupt handling mechanisms
- Hardware I/O operations
- Kernel logging and debugging

### System Security
- Kernel-level attack vectors
- Hardware-based monitoring
- Detection and prevention challenges

### Low-Level Programming
- Direct hardware access
- Scan code processing
- Timer programming
- Memory management in kernel space

## Safety Considerations

⚠️ **Important Safety Notes**:

1. **Educational Use Only**: This code is for learning purposes
2. **System Stability**: Kernel modules can crash the system if buggy
3. **Data Loss Risk**: Always save work before testing
4. **Legal Compliance**: Only use on systems you own or have permission to test
5. **Privacy Concerns**: Real keyloggers violate privacy and may be illegal

## Troubleshooting

### Common Issues

1. **Module won't load**:
   - Check kernel headers are installed
   - Verify you have root privileges
   - Check dmesg for error messages

2. **No keyboard input logged**:
   - Verify module is loaded (`lsmod | grep keylogger`)
   - Check if using USB keyboard (may need different approach)
   - Ensure interrupt sharing is working

3. **Compilation errors**:
   - Update kernel headers
   - Check gcc version compatibility
   - Verify Makefile paths

### Debugging Tips

1. **Use dmesg**: `dmesg | grep -i keylogger`
2. **Check module info**: `modinfo keylogger.ko`
3. **Monitor interrupts**: `cat /proc/interrupts | grep keyboard`
4. **Verify IRQ**: `cat /proc/interrupts | grep "1:"`

## Further Development

Potential enhancements for learning:

1. **File Output**: Write logs to a file instead of kernel buffer
2. **Network Transmission**: Send data over network
3. **Encryption**: Encrypt logged data
4. **Stealth Features**: Hide module from lsmod
5. **USB Keyboard Support**: Handle modern USB keyboards
6. **User-Space Communication**: Create device file for communication

## References

- [Linux Kernel Module Programming Guide](https://tldp.org/LDP/lkmpg/2.6/html/)
- [Linux Device Drivers (O'Reilly)](https://lwn.net/Kernel/LDD3/)
- [Kernel.org Documentation](https://www.kernel.org/doc/)
- [Linux Interrupt Handling](https://www.kernel.org/doc/html/latest/core-api/genericirq.html)

## License

This project is released under the GPL license for educational purposes only.
