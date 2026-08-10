# c64kit/video/vic.py
from ..core.constants import (
    VIC_BORDER, VIC_BG, VIC_RASTER, VIC_MEM, SCREEN_RAM
)
from ..core.memory import C64Memory

class VICII:
    """Wrapper class and emulator for Commodore 64 VIC-II registers ($D000 - $D02E)."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.mem.vic = self
        self.registers = bytearray(0x3F)  # Space for registers up to $D02F

        # Default standard register initializations
        self.registers[0x11] = 0x9B  # VIC_CTRL1 standard boot value
        self.registers[0x16] = 0x08  # VIC_CTRL2 standard boot value (40 col)
        self.registers[0x20] = 0x00  # Border (Black)
        self.registers[0x21] = 0x00  # Background (Black)

        self._raster_line = 0

    def read(self, addr: int) -> int:
        """Reads from VIC-II register space (mapped to $D000 - $D02E)."""
        reg = addr & 0x3F
        if reg == 0x12:  # VIC_RASTER
            # Simulate real raster scan increments on read
            self._raster_line = (self._raster_line + 1) % 312
            self.registers[0x12] = self._raster_line & 0xFF
            # Bit 7 of $D011 holds high bit of raster line
            ctrl1 = self.registers[0x11] & 0x7F
            if self._raster_line > 255:
                ctrl1 |= 0x80
            self.registers[0x11] = ctrl1
            return self.registers[0x12]

        if reg < len(self.registers):
            return self.registers[reg]
        return 0

    def write(self, addr: int, val: int) -> None:
        """Writes to VIC-II register space, triggering standard side effects."""
        reg = addr & 0x3F
        val &= 0xFF
        if reg < len(self.registers):
            self.registers[reg] = val

    def set_border_color(self, color: int) -> None:
        """Sets the border color ($D020)."""
        self.write(0xD020, color & 0x0F)

    def set_background_color(self, color: int) -> None:
        """Sets the background color ($D021)."""
        self.write(0xD021, color & 0x0F)

    def set_charset_location(self, addr: int) -> None:
        """Configures VIC_MEM ($D018) to point to custom charset."""
        val = (addr >> 10) & 0x3E
        self.write(0xD018, val)

    def get_raster_line(self) -> int:
        """Reads current simulated VIC_RASTER line ($D012)."""
        return self.read(0xD012)

    def wait_raster(self, line: int) -> None:
        """Emulates busy-waiting for a specific raster line."""
        self._raster_line = line & 0x1FF
        self.registers[0x12] = self._raster_line & 0xFF
        ctrl1 = self.registers[0x11] & 0x7F
        if self._raster_line > 255:
            ctrl1 |= 0x80
        self.registers[0x11] = ctrl1

    # --- Sprite Helpers ---

    def is_sprite_enabled(self, num: int) -> bool:
        """Returns True if sprite `num` (0-7) is enabled in $D015."""
        enabled_mask = self.read(0xD015)
        return bool(enabled_mask & (1 << num))

    def enable_sprite(self, num: int, enable: bool = True) -> None:
        """Enables or disables sprite `num` (0-7) in $D015."""
        current = self.read(0xD015)
        if enable:
            current |= (1 << num)
        else:
            current &= ~(1 << num)
        self.write(0xD015, current)

    def get_sprite_position(self, num: int) -> tuple:
        """Returns (x, y) coordinates of sprite `num` (0-7), handling $D010 MSB."""
        y = self.read(0xD001 + num * 2)
        x = self.read(0xD000 + num * 2)
        msb = self.read(0xD010)
        if msb & (1 << num):
            x += 256
        return x, y

    def set_sprite_position(self, num: int, x: int, y: int) -> None:
        """Sets (x, y) coordinates of sprite `num` (0-7) and updates $D010 MSB."""
        self.write(0xD001 + num * 2, y & 0xFF)
        self.write(0xD000 + num * 2, x & 0xFF)

        msb = self.read(0xD010)
        if x > 255:
            msb |= (1 << num)
        else:
            msb &= ~(1 << num)
        self.write(0xD010, msb)

    def get_sprite_color(self, num: int) -> int:
        """Returns color of sprite `num` (0-7) from $D027-$D02E."""
        return self.read(0xD027 + num) & 0x0F

    def set_sprite_color(self, num: int, color: int) -> None:
        """Sets color of sprite `num` (0-7) in $D027-$D02E."""
        self.write(0xD027 + num, color & 0x0F)

    def get_sprite_pointer(self, num: int) -> int:
        """Reads sprite data pointer (0-255) from standard $07F8-$07FF offsets."""
        # Use active VIC bank / Screen RAM address
        # Screen RAM defaults to $0400 on C64, making pointer block $07F8
        screen_bank = SCREEN_RAM
        return self.mem.read(screen_bank + 0x03F8 + num)

    def set_sprite_pointer(self, num: int, pointer: int) -> None:
        """Writes sprite data pointer (0-255) to standard $07F8-$07FF offsets."""
        screen_bank = SCREEN_RAM
        self.mem.write(screen_bank + 0x03F8 + num, pointer & 0xFF)

    # --- Scroll & Mode Helpers ---

    def get_scroll_x(self) -> int:
        """Returns horizontal scroll value (0-7) from $D016 bits 0-2."""
        return self.read(0xD016) & 0x07

    def set_scroll_x(self, scroll: int) -> None:
        """Sets horizontal scroll value (0-7) in $D016."""
        ctrl2 = self.read(0xD016) & 0xF8
        self.write(0xD016, ctrl2 | (scroll & 0x07))

    def get_scroll_y(self) -> int:
        """Returns vertical scroll value (0-7) from $D011 bits 0-2."""
        return self.read(0xD011) & 0x07

    def set_scroll_y(self, scroll: int) -> None:
        """Sets vertical scroll value (0-7) in $D011."""
        ctrl1 = self.read(0xD011) & 0xF8
        self.write(0xD011, ctrl1 | (scroll & 0x07))

    def is_multicolor_enabled(self) -> bool:
        """Returns True if multicolor mode is enabled on VIC-II ($D016 bit 4)."""
        return bool(self.read(0xD016) & 0x10)

    def set_multicolor_enabled(self, enabled: bool) -> None:
        """Enables or disables multicolor mode ($D016 bit 4)."""
        ctrl2 = self.read(0xD016)
        if enabled:
            ctrl2 |= 0x10
        else:
            ctrl2 &= ~0x10
        self.write(0xD016, ctrl2)
