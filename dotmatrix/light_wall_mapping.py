import csv


def load_light_wall_mapping(csv_file="dotmatrix/Light Wall Mapping.csv"):
    mapping = {}
    try:
        with open(csv_file, 'r') as f:
            reader = csv.reader(f)
            for row_idx, row in enumerate(reader):
                for col_idx, cell in enumerate(row):
                    if cell.strip():
                        try:
                            pixel_index = int(cell.strip()) - 1
                            if pixel_index >= 0:
                                mapping[(row_idx, col_idx)] = pixel_index
                        except ValueError:
                            pass
    except FileNotFoundError:
        for i in range(4500):
            row = i // 90
            col = i % 90
            mapping[(row, col)] = i
    return mapping


def create_fpp_buffer_from_grid(dot_colors, mapping):
    buffer = bytearray(13050)
    for (row, col), pixel_idx in mapping.items():
        if row < len(dot_colors) and col < len(dot_colors[0]):
            if pixel_idx < 0 or pixel_idx >= 4350:
                continue
            r, g, b = dot_colors[row][col]
            byte_idx = pixel_idx * 3
            if byte_idx + 2 < len(buffer):
                buffer[byte_idx] = r
                buffer[byte_idx + 1] = g
                buffer[byte_idx + 2] = b
    return buffer
