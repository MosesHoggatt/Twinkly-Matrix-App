import csv


def load_light_wall_mapping(csv_file="dotmatrix/Light Wall Mapping.csv"):
    """
    Load the Light Wall mapping CSV and create a lookup table.
    The CSV has physical grid layout where each cell contains the FPP pixel index.
    
    Returns a dictionary: (row, col) -> pixel_index
    """
    mapping = {}
    
    try:
        with open(csv_file, 'r') as f:
            reader = csv.reader(f)
            for row_idx, row in enumerate(reader):
                for col_idx, cell in enumerate(row):
                    if cell.strip():  # Only process non-empty cells
                        try:
                            pixel_index = int(cell.strip())
                            mapping[(row_idx, col_idx)] = pixel_index
                        except ValueError:
                            print(f"Warning: Invalid pixel index '{cell}' at ({row_idx}, {col_idx})")
    except FileNotFoundError:
        print(f"Error: Mapping file not found: {csv_file}")
        print("Using default linear mapping instead")
        # Fallback to linear mapping if CSV not found
        for i in range(4500):
            row = i // 90
            col = i % 90
            mapping[(row, col)] = i
    
    print(f"Loaded {len(mapping)} pixel mappings")
    if mapping:
        max_pixel = max(mapping.values())
        min_pixel = min(mapping.values())
        print(f"Pixel indices range: {min_pixel} to {max_pixel}")
    
    return mapping


def create_fpp_buffer_from_grid(dot_colors, mapping):
    """
    Convert a 2D grid of colors to FPP's expected buffer format using the mapping.
    
    Args:
        dot_colors: 2D list [row][col] = (r, g, b)
        mapping: dict of (row, col) -> pixel_index from CSV
    
    Returns:
        bytearray of 13500 bytes with proper FPP pixel ordering
    """
    buffer = bytearray(13500)
    
    for (row, col), pixel_idx in mapping.items():
        if row < len(dot_colors) and col < len(dot_colors[0]):
            # Bounds check: ensure pixel index is valid
            if pixel_idx < 0 or pixel_idx >= 4500:
                print(f"Warning: Invalid pixel index {pixel_idx} at grid ({row}, {col})")
                continue
            
            r, g, b = dot_colors[row][col]
            # Each pixel takes 3 bytes (RGB)
            byte_idx = pixel_idx * 3
            if byte_idx + 2 < len(buffer):
                buffer[byte_idx] = r
                buffer[byte_idx + 1] = g
                buffer[byte_idx + 2] = b
    
    return buffer
