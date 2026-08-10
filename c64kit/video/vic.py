# c64kit/video/vic.py
from ..core.constants import VIC_BORDER, VIC_BG, VIC_RASTER, VIC_MEM
from ..core.memory import C64Memory

class VICII:
    """Wrapper class for Commodore 64 VIC-II registers."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        # Initialize default border and background to Black (as in boot_sequence)
        self.mem.write(VIC_BORDER, 0)
        self.mem.write(VIC_BG, 0)
        self._raster_line = 0

    def set_border_color(self, color: int) -> None:
        """Sets the border color ($D020)."""
        self.mem.write(VIC_BORDER, color & 0x0F)

    def set_background_color(self, color: int) -> None:
        """Sets the background color ($D021)."""
        self.mem.write(VIC_BG, color & 0x0F)

    def set_charset_location(self, addr: int) -> None:
        """
        Configures VIC_MEM ($D018) to point to the charset.
        On C64, custom charset address needs to be configured in $D018.
        e.g., target_addr $3800 is value $1E.
        """
        # Map target address to $D018 bits (usually (addr >> 10) & 0x3C or similar)
        # $3800 -> 14th 2KB block, so 14 << 1 = 28 or $1C / $1E with screen address.
        # We store the raw register value in memory.
        val = (addr >> 10) & 0x3E
        self.mem.write(VIC_MEM, val)

    def get_raster_line(self) -> int:
        """Reads current simulated VIC_RASTER line ($D012)."""
        # Cycle raster line to simulate real CRT screen updates (PAL: 312, NTSC: 262)
        self._raster_line = (self._raster_line + 1) % 312
        self.mem.write(VIC_RASTER, self._raster_line & 0xFF)
        return self._raster_line

    def wait_raster(self, line: int) -> None:
        """Emulates busy-waiting for a specific raster line."""
        self._raster_line = line & 0xFF
        self.mem.write(VIC_RASTER, self._raster_line)
