#!/bin/bash

# BAW KeyLogger Test Script
# This script helps test the keylogger module functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root - be careful!"
        return 0
    else
        print_error "This script requires root privileges for module operations"
        print_status "Please run with: sudo $0"
        exit 1
    fi
}

# Function to check if kernel headers are installed
check_kernel_headers() {
    local kernel_version=$(uname -r)
    local headers_path="/lib/modules/$kernel_version/build"
    
    if [[ -d "$headers_path" ]]; then
        print_success "Kernel headers found at $headers_path"
        return 0
    else
        print_error "Kernel headers not found!"
        print_status "Install with: sudo apt install linux-headers-$(uname -r)"
        return 1
    fi
}

# Function to build the module
build_module() {
    print_status "Building keylogger module..."
    
    if make clean > /dev/null 2>&1; then
        print_success "Cleaned previous build files"
    fi
    
    if make all; then
        print_success "Module built successfully!"
        return 0
    else
        print_error "Failed to build module"
        return 1
    fi
}

# Function to load the module
load_module() {
    print_status "Loading keylogger module..."
    
    # Check if already loaded
    if lsmod | grep -q keylogger; then
        print_warning "Module already loaded, unloading first..."
        rmmod keylogger || true
    fi
    
    if insmod keylogger.ko; then
        print_success "Module loaded successfully!"
        
        # Show recent kernel messages
        print_status "Recent kernel messages:"
        dmesg | grep KeyLogger | tail -5
        return 0
    else
        print_error "Failed to load module"
        return 1
    fi
}

# Function to test basic functionality
test_basic_functionality() {
    print_status "Testing basic keylogger functionality..."
    print_status "The module should now be logging keystrokes to kernel messages"
    print_status "Type some keys and check the logs with: dmesg | grep KeyLogger"
    
    echo ""
    print_status "Press Enter to continue to Konami Code test..."
    read
}

# Function to test Konami Code
test_konami_code() {
    print_status "Testing Konami Code detection..."
    print_warning "Make sure your speakers are on to hear the melody!"
    
    echo ""
    print_status "The Konami Code sequence is: ↑↑↓↓←→←→BA"
    print_status "Use arrow keys, then press 'b' and 'a'"
    print_status "You should hear a melody when the sequence is completed"
    
    echo ""
    print_status "Try entering the Konami Code now..."
    print_status "Press Enter when done to check the logs..."
    read
    
    # Show recent logs
    print_status "Recent KeyLogger messages:"
    dmesg | grep KeyLogger | tail -10
}

# Function to monitor logs in real-time
monitor_logs() {
    print_status "Monitoring keylogger logs in real-time..."
    print_status "Press Ctrl+C to stop monitoring"
    
    echo ""
    print_status "Starting log monitor..."
    
    # Monitor kernel messages for keylogger output
    dmesg -w | grep --line-buffered KeyLogger
}

# Function to unload the module
unload_module() {
    print_status "Unloading keylogger module..."
    
    if lsmod | grep -q keylogger; then
        if rmmod keylogger; then
            print_success "Module unloaded successfully!"
            
            # Show final kernel messages
            print_status "Final kernel messages:"
            dmesg | grep KeyLogger | tail -3
        else
            print_error "Failed to unload module"
            return 1
        fi
    else
        print_warning "Module not currently loaded"
    fi
}

# Function to show module status
show_status() {
    print_status "Checking module status..."
    
    if lsmod | grep -q keylogger; then
        print_success "KeyLogger module is currently loaded"
        lsmod | grep keylogger
        
        # Show interrupt information
        print_status "Keyboard interrupt information:"
        cat /proc/interrupts | grep -E "(CPU|keyboard|1:)" | head -3
    else
        print_warning "KeyLogger module is not loaded"
    fi
}

# Function to show help
show_help() {
    echo "BAW KeyLogger Test Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  build     - Build the kernel module"
    echo "  load      - Load the module"
    echo "  test      - Run basic functionality test"
    echo "  konami    - Test Konami Code detection"
    echo "  monitor   - Monitor logs in real-time"
    echo "  status    - Show module status"
    echo "  unload    - Unload the module"
    echo "  full      - Run complete test sequence"
    echo "  help      - Show this help message"
    echo ""
    echo "Example full test sequence:"
    echo "  sudo $0 full"
}

# Main function for full test
run_full_test() {
    print_status "Starting full keylogger test sequence..."
    
    # Check prerequisites
    check_kernel_headers || exit 1
    
    # Build module
    build_module || exit 1
    
    # Load module
    load_module || exit 1
    
    # Show status
    show_status
    
    # Test basic functionality
    test_basic_functionality
    
    # Test Konami Code
    test_konami_code
    
    # Ask if user wants to monitor logs
    echo ""
    print_status "Would you like to monitor logs in real-time? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        monitor_logs
    fi
    
    # Unload module
    echo ""
    print_status "Test complete. Unloading module..."
    unload_module
    
    print_success "Full test sequence completed!"
}

# Main script logic
main() {
    case "${1:-help}" in
        "build")
            check_kernel_headers && build_module
            ;;
        "load")
            check_root && load_module
            ;;
        "test")
            test_basic_functionality
            ;;
        "konami")
            test_konami_code
            ;;
        "monitor")
            monitor_logs
            ;;
        "status")
            show_status
            ;;
        "unload")
            check_root && unload_module
            ;;
        "full")
            check_root && run_full_test
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
