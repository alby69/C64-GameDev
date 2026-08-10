# c64kit/core/memory.py
import random
from .constants import COLOR_RAM_BASE, SID_RANDOM

class C64Memory:
    """
    Flat 64KB memory model with banking I/O.
    Addresses mapped:
    - $0000-$00FF: Zero Page (game variables)
    - $0400-$07FF: Screen RAM (Video Matrix)
    - $3800-$3FFF: Custom Charset RAM
    - $D800-$DBFF: Color RAM (nibble-only)
    - $D41B: SID Noise generator (RNG)
    """

    def __init__(self):
        self.ram = bytearray(65536)
        self.color_ram = bytearray(1024)
        self.io_bank = True

    def read(self, addr: int) -> int:
        """Legge byte da indirizzo 16-bit con gestione banking."""
        addr &= 0xFFFF
        if 0xD800 <= addr <= 0xDBFF:
            return self.color_ram[addr - 0xD800] & 0x0F
        elif addr == SID_RANDOM:
            return random.randint(0, 255)
        return self.ram[addr]

    def write(self, addr: int, value: int) -> None:
        """Scrive byte con side-effect su I/O mapped."""
        addr &= 0xFFFF
        value &= 0xFF
        if 0xD800 <= addr <= 0xDBFF:
            self.color_ram[addr - 0xD800] = value & 0x0F
        else:
            self.ram[addr] = value

    def write_color(self, offset: int, color: int) -> None:
        """Scrive in Color RAM ($D800 base logica) tramite offset."""
        offset &= 0x3FF
        self.color_ram[offset] = color & 0x0F
