import pygame
import time
import mmap
import os
from .source_canvas import CanvasSource, SourcePreview
from .light_wall_mapping import load_light_wall_mapping, create_fpp_buffer_from_grid


class DotMatrix:
    def __init__(
        self,
        width=90,
        height=50,
        dot_size=6,
        spacing=15,
        should_stagger=True,
        blend_power=0.2,
        show_source_preview=False,
        supersample=3,
        headless=False,
        fpp_output=False,
        fpp_memory_buffer_file="/dev/shm/FPP-Model-Data-Light_Wall",
    ):
        self.width = width
        self.height = height
        self.dot_size = dot_size
        self.spacing = spacing
        self.should_stagger = should_stagger
        self.blend_power = blend_power
        self.supersample = max(1, int(supersample))
        self.headless = headless
        self.running = True
        
        self.fpp_memory_map = None
        self.fpp_memory_buffer_file = None
        self.fpp_mapping = load_light_wall_mapping() if fpp_output else None
        if fpp_output:
            self._initialize_fpp(fpp_memory_buffer_file)
        
        if not headless:
            pygame.init()

        self.bg_color = (0, 0, 0)
        self.off_color = (10, 10, 10)
        self.dot_colors = [[self.off_color for _ in range(width)] for _ in range(height)]
        
        window_width = width * (dot_size + spacing) + spacing
        window_height = height * (dot_size + spacing) + spacing
        
        if headless:
            self.screen = None
        else:
            self.screen = pygame.display.set_mode((window_width, window_height))
            pygame.display.set_caption("Dot Matrix Display")

        self.preview = SourcePreview(self.width, self.height, enabled=show_source_preview)
        self.clock = pygame.time.Clock() if not headless else None

    def _initialize_fpp(self, fpp_file):
        fpp_buffer_size = self.width * self.height * 3  # 87 * 50 * 3 = 13,050 bytes
        try:
            if not os.path.exists(fpp_file):
                try:
                    with open(fpp_file, 'wb') as fpp_file_handle:
                        fpp_file_handle.write(b'\x00' * fpp_buffer_size)
                except PermissionError:
                    print(f"Permission denied creating {fpp_file}")
                    print("Try running: sudo touch {}".format(fpp_file))
                    print("          sudo chmod 666 {}".format(fpp_file))
                    raise
            
            actual_file_size = os.path.getsize(fpp_file)
            mmap_size = min(fpp_buffer_size, actual_file_size)
            
            self.fpp_memory_buffer_file = open(fpp_file, 'r+b')
            self.fpp_memory_map = mmap.mmap(self.fpp_memory_buffer_file.fileno(), mmap_size)
        except PermissionError:
            print(f"Permission denied accessing {fpp_file}")
            print("Fix with: sudo chmod 666 {}".format(fpp_file))
            if self.fpp_memory_buffer_file:
                self.fpp_memory_buffer_file.close()
            self.fpp_memory_map = None
            self.fpp_memory_buffer_file = None
        except Exception as e:
            print(f"FPP output initialization failed: {e}")
            if self.fpp_memory_buffer_file:
                self.fpp_memory_buffer_file.close()
            self.fpp_memory_map = None
            self.fpp_memory_buffer_file = None

    def draw_on_twinklys(self):
        if not self.fpp_memory_map or not self.fpp_mapping:
            return
        
        scaled_grid = self._scale_grid_for_mapping(self.dot_colors)
        buffer = create_fpp_buffer_from_grid(scaled_grid, self.fpp_mapping)
        
        self.fpp_memory_map.seek(0)
        self.fpp_memory_map.write(buffer)
        self.fpp_memory_map.flush()

    def _scale_grid_for_mapping(self, grid):
        source_height = len(grid)
        source_width = len(grid[0]) if source_height else 0
        target_height = 100
        target_width = 90
        scaled = [[self.off_color for _ in range(target_width)] for _ in range(target_height)]
        for source_row in range(source_height):
            target_row_1 = source_row * 2
            target_row_2 = target_row_1 + 1
            for source_col in range(source_width):
                color = grid[source_row][source_col]
                scaled[target_row_1][source_col] = color
                if target_row_2 < target_height:
                    scaled[target_row_2][source_col] = color
        return scaled

    def draw_dot(self, dot_x, dot_y, color):
        if self.screen:
            pygame.draw.circle(self.screen, color, (dot_x, dot_y), self.dot_size)

    def visualize_matrix(self):
        if self.headless:
            return
            
        self.screen.fill(self.bg_color)
        stagger_offset = (self.dot_size / 2) + self.spacing / 2 if self.should_stagger else 0
        
        for row in range(self.height):
            for col in range(self.width):
                dot_x = self.spacing + col * (self.dot_size + self.spacing)
                dot_y = self.spacing + row * (self.dot_size + self.spacing) + (stagger_offset * (col % 2))
                self.draw_dot(dot_x, dot_y, self.dot_colors[row][col])
        
        pygame.display.flip()

    def convert_canvas_to_matrix(self, canvas): # Could be called every frame for moving canvases
        source_surface = canvas.surface if isinstance(canvas, CanvasSource) else canvas
        if self.preview:
            self.preview.update(source_surface)

        target_upsampled_size = (self.width * self.supersample, self.height * self.supersample)
        working_surface = source_surface
        if working_surface.get_size() != target_upsampled_size:
            working_surface = pygame.transform.smoothscale(working_surface, target_upsampled_size)

        scaled_surface = pygame.transform.smoothscale(working_surface, (self.width, self.height))
        
        samples = []
        max_luminance = 0.0
        for row in range(self.height):
            for col in range(self.width):
                color = scaled_surface.get_at((col, row))[:3]
                luminance = 0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2]
                samples.append((row, col, color, luminance))
                if luminance > max_luminance:
                    max_luminance = luminance

        max_normalized_luminance = max(1.0, max_luminance)
        blend_exponent = max(0.001, self.blend_power)
        
        for row, col, color, luminance in samples:
            blend_factor = max(0.0, min(1.0, luminance / max_normalized_luminance)) ** blend_exponent
            blended = tuple(
                int(self.off_color[channel_index] * (1.0 - blend_factor) + color[channel_index] * blend_factor)
                for channel_index in range(3)
            )
            self.dot_colors[row][col] = blended

        self.visualize_matrix()
        self.draw_on_twinklys()

    def render_sample_pattern(self):
        if self.headless:
            self._render_circle_pattern()
            self.draw_on_twinklys()
        else:
            pygame.init()
            high_res_width = self.width * self.supersample
            high_res_height = self.height * self.supersample
            source_canvas = CanvasSource.from_size(high_res_width, high_res_height)
            source_canvas.surface.fill((0, 0, 0))
            pygame.draw.circle(
                source_canvas.surface,
                (0, 200, 255),
                (high_res_width // 2, high_res_height // 2),
                min(high_res_width, high_res_height) // 3,
            )
            self.convert_canvas_to_matrix(source_canvas)
    
    def _render_circle_pattern(self):
        supersampled_width = self.width * self.supersample
        supersampled_height = self.height * self.supersample
        
        center_x = supersampled_width / 2
        center_y = supersampled_height / 2
        radius = min(supersampled_width, supersampled_height) / 3
        
        cyan = (0, 200, 255)
        off_color = self.off_color
        
        supersampled_grid = [[off_color for _ in range(supersampled_width)] for _ in range(supersampled_height)]
        
        for supersampled_row in range(supersampled_height):
            for supersampled_col in range(supersampled_width):
                delta_x = supersampled_col - center_x
                delta_y = supersampled_row - center_y
                distance = (delta_x * delta_x + delta_y * delta_y) ** 0.5
                
                if distance <= radius:
                    supersampled_grid[supersampled_row][supersampled_col] = cyan
        
        for row in range(self.height):
            for col in range(self.width):
                red_sum = green_sum = blue_sum = 0
                pixel_count = 0
                for supersampled_row in range(row * self.supersample, (row + 1) * self.supersample):
                    for supersampled_col in range(col * self.supersample, (col + 1) * self.supersample):
                        red, green, blue = supersampled_grid[supersampled_row][supersampled_col]
                        red_sum += red
                        green_sum += green
                        blue_sum += blue
                        pixel_count += 1
                
                red_avg = int(red_sum / pixel_count)
                green_avg = int(green_sum / pixel_count)
                blue_avg = int(blue_sum / pixel_count)
                self.dot_colors[row][col] = (red_avg, green_avg, blue_avg)

    def render_image(self, image_path):
        source_canvas = CanvasSource.from_image(image_path, size=(self.width, self.height))
        self.convert_canvas_to_matrix(source_canvas)

    def wait_for_exit(self):
        if self.headless:
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                pass
            finally:
                self._turn_off_all_lights()
        else:
            try:
                while self.running:
                    for event in pygame.event.get():
                        if event.type == pygame.QUIT:
                            self.running = False
                    
                    if self.clock:
                        self.clock.tick(40)
            except KeyboardInterrupt:
                pass
            finally:
                self._turn_off_all_lights()
                pygame.quit()
    
    def _turn_off_all_lights(self):
        for row in range(self.height):
            for col in range(self.width):
                self.dot_colors[row][col] = (0, 0, 0)
        
        if self.fpp_memory_map:
            self.draw_on_twinklys()
            self.fpp_memory_map.close()
        if self.fpp_memory_buffer_file:
            self.fpp_memory_buffer_file.close()