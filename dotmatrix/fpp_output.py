import mmap
import time
import os
from .light_wall_mapping import load_light_wall_mapping, create_fpp_buffer_from_grid


class FPPOutput:
    def __init__(self, width=90, height=50, fpp_file="/dev/shm/FPP-Model-Data-Light_Wall"):
        self.width = width
        self.height = height
        self.fpp_file = fpp_file
        self.buffer_size = width * height * 3
        self.memory_map = None
        self.memory_buffer_file = None
        self.mapping = load_light_wall_mapping()
        self._initialize_mmap()
    
    def _initialize_mmap(self):
        try:
            if not os.path.exists(self.fpp_file):
                try:
                    with open(self.fpp_file, 'wb') as fpp_file_handle:
                        fpp_file_handle.write(b'\x00' * self.buffer_size)
                except PermissionError:
                    print(f"Permission denied creating {self.fpp_file}")
                    print("Try running: sudo touch {}".format(self.fpp_file))
                    print("          sudo chmod 666 {}".format(self.fpp_file))
                    raise
            
            self.memory_buffer_file = open(self.fpp_file, 'r+b')
            self.memory_map = mmap.mmap(self.memory_buffer_file.fileno(), self.buffer_size)
        except PermissionError as exception:
            print(f"Permission denied accessing {self.fpp_file}")
            print("Fix with: sudo chmod 666 {}".format(self.fpp_file))
            if self.memory_buffer_file:
                self.memory_buffer_file.close()
            self.memory_map = None
            self.memory_buffer_file = None
        except Exception as exception:
            print(f"Failed to initialize FPP output: {exception}")
            if self.memory_buffer_file:
                self.memory_buffer_file.close()
            self.memory_map = None
            self.memory_buffer_file = None
    
    def write_matrix(self, dot_colors):
        if not self.memory_map:
            return
        
        buffer = create_fpp_buffer_from_grid(dot_colors, self.mapping)
        
        self.memory_map.seek(0)
        self.memory_map.write(buffer)
        self.memory_map.flush()
    
    def verify_write(self):
        if not self.memory_map:
            return False
        
        test_buffer = bytearray(self.buffer_size)
        test_buffer[0:3] = b'\xFF\x00\x00'
        
        self.memory_map.seek(0)
        self.memory_map.write(test_buffer)
        self.memory_map.flush()
        
        self.memory_map.seek(0)
        return self.memory_map.read(3) == b'\xFF\x00\x00'
    
    def clear(self):
        if self.memory_map:
            self.memory_map.seek(0)
            self.memory_map.write(b'\x00' * self.buffer_size)
            self.memory_map.flush()
    
    def close(self):
        if self.memory_map:
            self.memory_map.close()
        if self.memory_buffer_file:
            self.memory_buffer_file.close()
