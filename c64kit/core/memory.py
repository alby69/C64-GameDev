# c64kit/core/memory.py
import random
from .constants import COLOR_RAM_BASE, SID_RANDOM

class C64Memory:
    """
    Flat 64KB memory model with C64 hardware bank switching ($0001).
    Supports ROM overlay (BASIC, KERNAL, CHARGEN) and IO-mapped hardware routing.
    """

    def __init__(self):
        self.ram = bytearray(65536)
        self.color_ram = bytearray(1024)

        # ROM definitions
        self.basic_rom = bytearray(8192)
        self.kernal_rom = bytearray(8192)
        self.chargen_rom = bytearray(4096)

        # Initialize processor port and data direction registers
        self.ram[0x0000] = 0x2F
        self.ram[0x0001] = 0x37  # Default configuration (LORAM, HIRAM, CHAREN are all 1)

        # Registered hardware devices
        self.vic = None
        self.sid = None
        self.cia1 = None
        self.cia2 = None

    def get_bank_config(self) -> tuple:
        """
        Extracts banking configuration flags based on $0001 bits.
        Returns:
            (loram, hiram, charen)
        """
        port = self.ram[0x0001]
        loram = bool(port & 0x01)
        hiram = bool(port & 0x02)
        charen = bool(port & 0x04)
        return loram, hiram, charen

    def read(self, addr: int) -> int:
        """Reads a byte from memory with bank switching rules."""
        addr &= 0xFFFF
        loram, hiram, charen = self.get_bank_config()

        # 1. BASIC ROM region ($A000 - $BFFF)
        if 0xA000 <= addr <= 0xBFFF:
            if loram and hiram:
                return self.basic_rom[addr - 0xA000]
            return self.ram[addr]

        # 2. KERNAL ROM region ($E000 - $FFFF)
        elif 0xE000 <= addr <= 0xFFFF:
            if hiram:
                return self.kernal_rom[addr - 0xE000]
            return self.ram[addr]

        # 3. I/O / CHARGEN / RAM region ($D000 - $DFFF)
        elif 0xD000 <= addr <= 0xDFFF:
            # If both hiram and loram are 0, it's flat RAM
            if not hiram and not loram:
                return self.ram[addr]

            # If CHAREN is 1, access I/O space
            if charen:
                # Color RAM ($D800 - $DBFF)
                if 0xD800 <= addr <= 0xDBFF:
                    return self.color_ram[addr - 0xD800] & 0x0F

                # SID RNG Register
                elif addr == SID_RANDOM:
                    if self.sid and hasattr(self.sid, 'read_random'):
                        return self.sid.read_random()
                    return random.randint(0, 255)

                # Hardware device routing
                elif 0xD000 <= addr <= 0xD02E and self.vic:
                    if hasattr(self.vic, 'read'):
                        return self.vic.read(addr)
                elif 0xD400 <= addr <= 0xD41C and self.sid:
                    if hasattr(self.sid, 'read'):
                        return self.sid.read(addr)
                elif 0xDC00 <= addr <= 0xDC0F and self.cia1:
                    if hasattr(self.cia1, 'read'):
                        return self.cia1.read(addr)
                elif 0xDD00 <= addr <= 0xDD0F and self.cia2:
                    if hasattr(self.cia2, 'read'):
                        return self.cia2.read(addr)

                return self.ram[addr]

            # Else if CHAREN is 0, access CHARGEN ROM
            else:
                return self.chargen_rom[addr - 0xD000]

        # Default fallback is normal RAM
        return self.ram[addr]

    def write(self, addr: int, value: int) -> None:
        """Writes a byte to memory, respecting I/O routing and ROM write-through."""
        addr &= 0xFFFF
        value &= 0xFF
        loram, hiram, charen = self.get_bank_config()

        # Processor Port write
        if addr == 0x0001:
            self.ram[0x0001] = value
            return

        # I/O space writing ($D000 - $DFFF)
        if 0xD000 <= addr <= 0xDFFF:
            # IO is mapped if charen is 1, and hiram or loram is 1
            if charen and (hiram or loram):
                if 0xD800 <= addr <= 0xDBFF:
                    self.color_ram[addr - 0xD800] = value & 0x0F
                    return

                # Hardware device routing
                elif 0xD000 <= addr <= 0xD02E and self.vic:
                    if hasattr(self.vic, 'write'):
                        self.vic.write(addr, value)
                    else:
                        self.ram[addr] = value
                elif 0xD400 <= addr <= 0xD41C and self.sid:
                    if hasattr(self.sid, 'write'):
                        self.sid.write(addr, value)
                    else:
                        self.ram[addr] = value
                elif 0xDC00 <= addr <= 0xDC0F and self.cia1:
                    if hasattr(self.cia1, 'write'):
                        self.cia1.write(addr, value)
                    else:
                        self.ram[addr] = value
                elif 0xDD00 <= addr <= 0xDD0F and self.cia2:
                    if hasattr(self.cia2, 'write'):
                        self.cia2.write(addr, value)
                    else:
                        self.ram[addr] = value
                else:
                    self.ram[addr] = value
                return

        # Writes to ROM-mapped areas always write through to the underlying RAM on a C64.
        self.ram[addr] = value

    def write_color(self, offset: int, color: int) -> None:
        """Writes to Color RAM using an offset (0 - 1023)."""
        offset &= 0x3FF
        self.color_ram[offset] = color & 0x0F
