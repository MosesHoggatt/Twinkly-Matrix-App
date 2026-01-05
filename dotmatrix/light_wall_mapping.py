import csv


def load_light_wall_mapping(csv_file="dotmatrix/Light Wall Mapping.csv"):
    mapping = {}
    try:
        with open(csv_file, 'r') as csv_file_handle:
            reader = csv.reader(csv_file_handle)
            for row_index, row in enumerate(reader):
                for column_index, cell in enumerate(row):
                    if cell.strip():
                        try:
                            pixel_index = int(cell.strip()) - 1
                            if pixel_index >= 0:
                                mapping[(row_index, column_index)] = pixel_index
                        except ValueError:
                            pass
    except FileNotFoundError:
        for pixel_number in range(4500):
            row_number = pixel_number // 90
            column_number = pixel_number % 90
            mapping[(row_number, column_number)] = pixel_number
    return mapping


def create_fpp_buffer_from_grid(dot_colors, mapping):
    buffer = bytearray(13050)
    for (grid_row, grid_col), pixel_index in mapping.items():
        if grid_row < len(dot_colors) and grid_col < len(dot_colors[0]):
            if pixel_index < 0 or pixel_index >= 4350:
                continue
            red, green, blue = dot_colors[grid_row][grid_col]
            byte_index = pixel_index * 3
            if byte_index + 2 < len(buffer):
                buffer[byte_index] = red
                buffer[byte_index + 1] = green
                buffer[byte_index + 2] = blue
    return buffer
