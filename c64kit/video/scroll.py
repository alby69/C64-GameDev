# c64kit/video/scroll.py
from typing import List, Tuple, Optional
from ..core.memory import C64Memory
from .vic import VICII

class Scroll:
    """Manages smooth scrolling and tilemap background handling for the C64 kit."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.vic = memory.vic if memory.vic else VICII(memory)
        self.tilemap: List[List[Tuple[int, int]]] = []  # Store (char_code, color)
        self.tilemap_width = 0
        self.tilemap_height = 0
        self.view_x = 0
        self.view_y = 0

        self.active_screen = 0x0400
        self.hidden_screen = 0x0800
        self.double_buffer_enabled = False

    def set_scroll_x(self, val: int) -> None:
        """Sets fine scroll X offset (0-7)."""
        self.vic.set_scroll_x(val & 0x07)

    def set_scroll_y(self, val: int) -> None:
        """Sets fine scroll Y offset (0-7)."""
        self.vic.set_scroll_y(val & 0x07)

    def init_tilemap(self, width: int, height: int) -> None:
        """Initializes a virtual tilemap buffer (width x height) with empty chars."""
        self.tilemap_width = width
        self.tilemap_height = height
        # Fill with spaces (0x20) and White (1)
        self.tilemap = [[(0x20, 1) for _ in range(width)] for _ in range(height)]
        self.view_x = 0
        self.view_y = 0

    def set_tile(self, x: int, y: int, char_code: int, color: int) -> None:
        """Sets a tile (char and color) in the tilemap."""
        if 0 <= x < self.tilemap_width and 0 <= y < self.tilemap_height:
            self.tilemap[y][x] = (char_code & 0xFF, color & 0x0F)

    def set_double_buffer(self, active_addr: int, hidden_addr: int) -> None:
        """Configures double buffering parameters."""
        self.active_screen = active_addr & 0xFC00
        self.hidden_screen = hidden_addr & 0xFC00
        self.double_buffer_enabled = True

    def swap_buffers(self) -> None:
        """Swaps the active and hidden video buffers and registers the bank shift in VIC-II."""
        if not self.double_buffer_enabled:
            return
        self.active_screen, self.hidden_screen = self.hidden_screen, self.active_screen
        # Update VIC register $D018 with new screen memory offset
        # bits 4-7 of $D018 specify starting block of Screen RAM (addr / 1024)
        val = self.vic.read(0xD018) & 0x0F
        screen_block = (self.active_screen >> 10) & 0x0F
        self.vic.write(0xD018, val | (screen_block << 4))

    def render_viewport(self) -> None:
        """
        Renders the active viewport area (40x25 characters)
        from the tilemap onto the current active screen memory.
        """
        if not self.tilemap:
            return

        for row in range(25):
            ty = (self.view_y + row) % self.tilemap_height
            for col in range(40):
                tx = (self.view_x + col) % self.tilemap_width
                char_code, color = self.tilemap[ty][tx]

                screen_offset = row * 40 + col
                self.mem.write(self.active_screen + screen_offset, char_code)
                self.mem.write_color(screen_offset, color)

    def scroll_tilemap(self, dx: int, dy: int) -> None:
        """Moves the viewport across the tilemap and triggers a redraw."""
        self.view_x = (self.view_x + dx) % max(1, self.tilemap_width)
        self.view_y = (self.view_y + dy) % max(1, self.tilemap_height)
        self.render_viewport()
