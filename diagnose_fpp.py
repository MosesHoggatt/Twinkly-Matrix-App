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
    
    # Calculate possible dimensions based on actual file size
    file_size = stat_info.st_size
    pixels = file_size // 3
    
    print(f"\n  Total pixels: {pixels}")
    
    # Try to find dimensions
    possible_dims = [
        (90, 50, "Current FPP config"),
        (87, 50, "Original spec"),
        (100, 45, "Alternative"),
        (int(pixels**0.5), int(pixels**0.5), "Square"),
    ]
    
    for width, height, desc in possible_dims:
        if width * height == pixels:
            print(f"  ✓ Matches {width}x{height} ({desc})")
    
    expected_size = 90 * 50 * 3  # 13500
    actual_size = stat_info.st_size
    
    print(f"\n  Expected size: {expected_size} bytes (90x50x3)"))
    print(f"  Actual size: {actual_size} bytes")
    print(f"  Difference: {actual_size - expected_size} bytes")
    
    # Read current content
    with open(FPP_FILE, 'r+b') as f:
        mm = mmap.mmap(f.fileno(), 0)  # Map entire file
        
        mm.seek(0)
        current = mm.read(30)
        print(f"\n  Current first 30 bytes: {current.hex()}")
        
        # Check if file contains any non-zero data
        mm.seek(0)
        data = mm.read(min(300, len(mm)))
        non_zero = sum(1 for b in data if b != 0)
        print(f"  Non-zero bytes in first 300: {non_zero}")
        
        # Write test pattern at start
        mm.seek(0)
        mm.write(b'\xFF\x00\x00' * 10)  # Red for first 10 pixels
        mm.flush()
        
        print("\n  Wrote red test pattern (first 10 pixels = FF0000...)")
        time.sleep(1)
        
        # Check if FPP modified it
        mm.seek(0)
        after = mm.read(30)
        
        if after == b'\xFF\x00\x00' * 10:
            print("  → File UNCHANGED (FPP NOT reading from this location)")
        else:
            print("  → File CHANGED (FPP IS reading!)")
            print(f"    New content: {after.hex()}")
        
        # Try writing to different offsets to see if FPP is reading elsewhere
        print("\n  Testing if FPP reads from other offsets...")
        test_offsets = [0, 100, 1000, 5000, 10000]
        
        for offset in test_offsets:
            if offset + 3 <= len(mm):
                mm.seek(offset)
                mm.write(b'\x00\xFF\x00')  # Green
                mm.flush()
                time.sleep(0.2)
                mm.seek(offset)
                result = mm.read(3)
                if result != b'\x00\xFF\x00':
                    print(f"    Offset {offset}: FPP modified! (reading from here?)")
        
        mm.close()
    
    print("\n" + "="*60)
    print("IMPORTANT: File size mismatch detected!")
    print(f"Expected: 13050 bytes (87×50×3)")
    print(f"Actual: {actual_size} bytes")
    print("\nFPP may be configured for different dimensions!")
    print("="*60)
    print("\nNext steps:")
    print("1. Check FPP model configuration:")
    print("   - SSH to FPP and check ~/.fpp/ directory")
    print("   - Look for model/output configuration files")
    print("   - Verify the 'Light_Wall' model dimensions")
    print("\n2. Common FPP configurations:")
    print("   - Check: fpp-model.json or similar")
    print("   - Look for 'width', 'height', 'pixelCount'")
    print("\n3. Alternative shared memory locations:")
    print("   - ls -la /dev/shm/ | grep -i fpp")
    print("   - ls -la /dev/shm/ | grep -i model")
    print("\n4. Check FPP web interface:")
    print("   - URL: http://<fpp-ip>/")
    print("   - Check Model tab for actual dimensions")
    print("   - Check Output configuration")

if __name__ == "__main__":
    check_fpp_status()

