# c64kit/video/screen.py
from ..core.constants import SCREEN_RAM, COLOR_RAM_BASE
from ..core.memory import C64Memory
from .colors import Colors

class Screen:
    """Wrapper class for Commodore 64 Screen RAM (40 columns x 25 rows)."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.width = 40
        self.height = 25

    def clear(self, char: int = 0x20, color: int = 0) -> None:
        """Fills Screen RAM with 'char' and Color RAM with 'color'."""
        for offset in range(1000):
            self.mem.write(SCREEN_RAM + offset, char)
            self.mem.write_color(offset, color)

    def poke_char(self, x: int, y: int, char: int, color: int = None) -> None:
        """Writes character screen code at (x, y). Optionally updates Color RAM."""
        if 0 <= x < self.width and 0 <= y < self.height:
            offset = y * self.width + x
            self.mem.write(SCREEN_RAM + offset, char)
            if color is not None:
                self.mem.write_color(offset, color)

    def poke_string(self, x: int, y: int, text: str, color: int = None) -> None:
        """Prints an ASCII string converted to Screen Codes starting at (x, y)."""
        from ..core.utils import ascii_to_screen_code
        for i, char in enumerate(text):
            self.poke_char(x + i, y, ascii_to_screen_code(char), color)

    def draw_sprite(self, x: int, y: int, sprite_id: int, frame: int = 0, color: int = None) -> None:
        """
        Draws a 5x3 sprite at (x, y) based on SPRDATA_BASE from GameData.
        sprite_id: 0 = player, 1-3 = invader types, 4 = bonus
        frame: 0 or 1.
        """
        from ..game.sprite_data import GameData
        base_offset = (sprite_id + frame * 4) * 16
        # The first byte is the sprite ID/metadata byte, the next 15 bytes are actual sprite characters.
        sprite_bytes = GameData.SPRDATA_BASE[base_offset + 1 : base_offset + 16]

        for row in range(3):
            for col in range(5):
                char = sprite_bytes[row * 5 + col]
                self.poke_char(x + col, y + row, char, color)

    def draw_bunker(self, base_addr: int, pattern: bytes) -> None:
        """
        Draws bunker using the specified pattern at C64 memory address base_addr.
        Equivalente a L0D88.
        """
        for i in range(0, len(pattern) - 1, 2):
            char = pattern[i]
            offset = pattern[i+1]
            if char == 0:
                break
            # Write directly to mapped memory
            self.mem.write(base_addr + offset, char)

    def sync_raster(self, line: int = 0x80) -> None:
        """Simulates waiting for the raster line ($D012)."""
        from ..core.constants import VIC_RASTER
        self.mem.write(VIC_RASTER, line & 0xFF)
