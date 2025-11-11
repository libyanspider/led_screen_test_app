#!/usr/bin/env python3
"""
Quick test script for LED Interactive Demo
Sends the example packets from the protocol documentation
"""

import socket
import time

def send_test_packets():
    print("LED Interactive Quick Test")
    print("=" * 50)
    
    # Create UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    target = ('127.0.0.1', 25000)
    
    try:
        # Example 1: Single point at X=285, Y=5
        print("\nSending Example 1: Single point at X=285, Y=5")
        example1 = bytes([0x86, 0x55, 0x01, 0x00, 0x01, 0x00, 0x1D, 0x01, 0x05, 0x00])
        sock.sendto(example1, target)
        print(f"Sent: {' '.join(f'{b:02X}' for b in example1)}")
        time.sleep(2)
        
        # Example 2: Two points
        print("\nSending Example 2: Two points at (245,5) and (255,15)")
        example2 = bytes([0xCA, 0x56, 0x01, 0x00, 0x02, 0x00, 
                         0xF5, 0x00, 0x05, 0x00, 
                         0xFF, 0x00, 0x0F, 0x00])
        sock.sendto(example2, target)
        print(f"Sent: {' '.join(f'{b:02X}' for b in example2)}")
        time.sleep(2)
        
        # Send a few animated points
        print("\nSending animated points (5 seconds)...")
        for i in range(50):
            x = 100 + i * 10
            y = 200 + i * 5
            
            # Create packet: frame_num (2), ignore (2), num_points (2), x (2), y (2)
            packet = bytes([
                i & 0xFF, (i >> 8) & 0xFF,  # frame number
                0x01, 0x00,                   # ignore
                0x01, 0x00,                   # 1 point
                x & 0xFF, (x >> 8) & 0xFF,   # X coordinate
                y & 0xFF, (y >> 8) & 0xFF,   # Y coordinate
            ])
            
            sock.sendto(packet, target)
            print(f"\rFrame {i}: X={x}, Y={y}", end='', flush=True)
            time.sleep(0.1)
        
        print("\n\nTest complete! Check the app for received coordinates.")
        
    except Exception as e:
        print(f"\nError: {e}")
    finally:
        sock.close()

if __name__ == '__main__':
    send_test_packets()
