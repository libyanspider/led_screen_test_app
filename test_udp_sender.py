#!/usr/bin/env python3
"""
LED Interactive Protocol Test UDP Sender

This script sends test UDP packets to simulate LED interactive sensor data.
Use it to test the Flutter app without actual hardware.

Usage:
    python test_udp_sender.py [target_ip]

If no IP is provided, it defaults to localhost (127.0.0.1)
"""

import socket
import struct
import time
import random
import sys

def create_packet(frame_num, points):
    """
    Create a UDP packet according to LED Interactive protocol.
    
    Args:
        frame_num: Frame number (0-65535)
        points: List of tuples [(x1, y1), (x2, y2), ...]
    
    Returns:
        bytes: The formatted packet
    """
    num_points = len(points)
    
    # Start with header: frame_num (2 bytes), ignore (2 bytes), num_points (2 bytes)
    packet = struct.pack('<HHH', 
                        frame_num,      # Frame number
                        0x0001,         # Ignore field
                        num_points)     # Number of points
    
    # Add each point (x, y coordinates)
    for x, y in points:
        packet += struct.pack('<HH', x, y)
    
    return packet

def send_single_point_demo(sock, target):
    """Send a single point moving in a circle pattern"""
    print("\n=== Single Point Demo (Circle Pattern) ===")
    
    center_x, center_y = 500, 500
    radius = 200
    
    for frame in range(360):
        angle = (frame * 3.14159 / 180) * 2  # Convert to radians
        x = int(center_x + radius * (angle / 6.28318))
        y = int(center_y + radius * ((angle * 2) % 6.28318 / 6.28318 - 0.5) * 2)
        
        packet = create_packet(frame, [(x, y)])
        sock.sendto(packet, target)
        
        hex_data = ' '.join(f'{b:02X}' for b in packet)
        print(f"Frame {frame:3d}: X={x:4d}, Y={y:4d} | {hex_data}")
        
        time.sleep(0.05)  # 20 fps
        
        if frame % 90 == 89:
            time.sleep(0.5)  # Pause at quarter circles

def send_two_points_demo(sock, target):
    """Send two points moving in opposite directions"""
    print("\n=== Two Points Demo (Opposite Movement) ===")
    
    for frame in range(100):
        x1 = 100 + frame * 8
        y1 = 200 + int(50 * (frame % 20) / 10)
        
        x2 = 900 - frame * 8
        y2 = 600 - int(50 * (frame % 20) / 10)
        
        packet = create_packet(frame, [(x1, y1), (x2, y2)])
        sock.sendto(packet, target)
        
        hex_data = ' '.join(f'{b:02X}' for b in packet)
        print(f"Frame {frame:3d}: Point1=({x1:4d},{y1:4d}) Point2=({x2:4d},{y2:4d}) | {hex_data}")
        
        time.sleep(0.05)

def send_random_multi_point_demo(sock, target):
    """Send random number of points (1-5) at random positions"""
    print("\n=== Random Multi-Point Demo ===")
    
    for frame in range(50):
        num_points = random.randint(1, 5)
        points = [(random.randint(0, 1920), random.randint(0, 1080)) 
                  for _ in range(num_points)]
        
        packet = create_packet(frame, points)
        sock.sendto(packet, target)
        
        hex_data = ' '.join(f'{b:02X}' for b in packet)
        points_str = ', '.join(f'({x},{y})' for x, y in points)
        print(f"Frame {frame:3d}: {num_points} points: {points_str}")
        print(f"           Hex: {hex_data}")
        
        time.sleep(0.1)

def send_test_examples(sock, target):
    """Send the exact examples from the protocol documentation"""
    print("\n=== Protocol Documentation Examples ===")
    
    # Example 1: 86 55 01 00 01 00 1D 01 05 00
    print("\nExample 1: Single point at X=285, Y=5")
    example1 = bytes([0x86, 0x55, 0x01, 0x00, 0x01, 0x00, 0x1D, 0x01, 0x05, 0x00])
    sock.sendto(example1, target)
    hex_data = ' '.join(f'{b:02X}' for b in example1)
    print(f"Sent: {hex_data}")
    time.sleep(1)
    
    # Example 2: CA 56 01 00 02 00 F5 00 05 00 FF 00 0F 00
    print("\nExample 2: Two points at (245,5) and (255,15)")
    example2 = bytes([0xCA, 0x56, 0x01, 0x00, 0x02, 0x00, 
                     0xF5, 0x00, 0x05, 0x00, 
                     0xFF, 0x00, 0x0F, 0x00])
    sock.sendto(example2, target)
    hex_data = ' '.join(f'{b:02X}' for b in example2)
    print(f"Sent: {hex_data}")
    time.sleep(1)

def main():
    # Get target IP from command line or use localhost
    target_ip = sys.argv[1] if len(sys.argv) > 1 else '127.0.0.1'
    target_port = 25000
    
    print("=" * 60)
    print("LED Interactive Protocol Test UDP Sender")
    print("=" * 60)
    print(f"Target: {target_ip}:{target_port}")
    print("=" * 60)
    
    # Create UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    target = (target_ip, target_port)
    
    try:
        while True:
            print("\nSelect test mode:")
            print("1. Protocol documentation examples")
            print("2. Single point (circle pattern)")
            print("3. Two points (opposite movement)")
            print("4. Random multi-point")
            print("5. Continuous random stream")
            print("6. Exit")
            
            choice = input("\nEnter choice (1-6): ").strip()
            
            if choice == '1':
                send_test_examples(sock, target)
            elif choice == '2':
                send_single_point_demo(sock, target)
            elif choice == '3':
                send_two_points_demo(sock, target)
            elif choice == '4':
                send_random_multi_point_demo(sock, target)
            elif choice == '5':
                print("\n=== Continuous Random Stream (Press Ctrl+C to stop) ===")
                try:
                    frame = 0
                    while True:
                        num_points = random.randint(1, 3)
                        points = [(random.randint(0, 1920), random.randint(0, 1080)) 
                                  for _ in range(num_points)]
                        packet = create_packet(frame % 65536, points)
                        sock.sendto(packet, target)
                        
                        points_str = ', '.join(f'({x},{y})' for x, y in points)
                        print(f"\rFrame {frame:5d}: {points_str:<60}", end='', flush=True)
                        
                        frame += 1
                        time.sleep(0.033)  # ~30 fps
                except KeyboardInterrupt:
                    print("\n\nStream stopped.")
            elif choice == '6':
                print("\nExiting...")
                break
            else:
                print("\nInvalid choice. Please try again.")
    
    except KeyboardInterrupt:
        print("\n\nInterrupted by user.")
    finally:
        sock.close()
        print("Socket closed. Goodbye!")

if __name__ == '__main__':
    main()
