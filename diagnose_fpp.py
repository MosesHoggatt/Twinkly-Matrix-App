#!/usr/bin/env python3
import mmap
import os
import time

FPP_FILE = "/dev/shm/FPP-Model-Data-Light_Wall"

def check_fpp_status():
    """Check FPP shared memory file status and content"""
    
    if not os.path.exists(FPP_FILE):
        print(f"✗ {FPP_FILE} does not exist")
        return
    
    stat_info = os.stat(FPP_FILE)
    print(f"✓ File exists: {FPP_FILE}")
    print(f"  Size: {stat_info.st_size} bytes")
    print(f"  Permissions: {oct(stat_info.st_mode)[-3:]}")
    
    width, height = 87, 50
    expected_size = width * height * 3
    
    if stat_info.st_size < expected_size:
        print(f"  ⚠ Warning: File is smaller than expected")
        print(f"    Expected: {expected_size} bytes (87x50x3)")
        print(f"    Actual: {stat_info.st_size} bytes")
    elif stat_info.st_size > expected_size:
        print(f"  ⚠ Warning: File is larger than expected")
        print(f"    Expected: {expected_size} bytes (87x50x3)")
        print(f"    Actual: {stat_info.st_size} bytes")
    
    # Check if file is being read by FPP
    with open(FPP_FILE, 'r+b') as f:
        mm = mmap.mmap(f.fileno(), expected_size)
        
        # Read current content
        mm.seek(0)
        current = mm.read(30)
        print(f"\n  Current first 30 bytes: {current.hex()}")
        
        # Write test pattern
        mm.seek(0)
        mm.write(b'\xFF\x00\x00' * 10)  # Red for first 10 pixels
        mm.flush()
        
        print("\n  Wrote red test pattern (first 10 pixels)")
        time.sleep(0.5)
        
        # Check if FPP modified it
        mm.seek(0)
        after = mm.read(30)
        
        if after == b'\xFF\x00\x00' * 10:
            print("  → File unchanged after write (FPP may not be reading this location)")
        else:
            print("  → File changed after write! (FPP is reading and modifying)")
            print(f"    New content: {after.hex()}")
        
        mm.close()
    
    print("\nDiagnostic steps:")
    print("1. Check FPP's model configuration for the exact shared memory location")
    print("2. Verify FPP is running: ps aux | grep fpp")
    print("3. Check FPP logs: tail -f /tmp/fpp.log")
    print("4. Verify LED model is properly assigned in FPP")
    print("5. Check if FPP expects a different pixel format (RGB vs BGR vs GRB)")

if __name__ == "__main__":
    check_fpp_status()
