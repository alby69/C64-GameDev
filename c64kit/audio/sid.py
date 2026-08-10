# c64kit/audio/sid.py
import random
from ..core.constants import (
    SID_VOL, SID_FREQ_LO1, SID_FREQ_HI1, SID_CTRL1,
    SID_ATT_DEC1, SID_SUST_REL1, SID_RANDOM
)
from ..core.memory import C64Memory

class SID:
    """Wrapper class for Commodore 64 SID 6581/8580 chip."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.init()

    def init(self) -> None:
        """Initializes the SID chip registers."""
        self.set_volume(0x0F)
        self.mem.write(SID_FREQ_LO1, 0)
        self.mem.write(SID_FREQ_HI1, 0)
        self.mem.write(SID_CTRL1, 0)
        self.set_adsr(0x00, 0x08, 0x0A, 0x08)  # Quick attack, slow decay/release

    def set_volume(self, vol: int) -> None:
        """Sets the SID master volume ($D418)."""
        self.mem.write(SID_VOL, vol & 0x0F)

    def play_tone(self, freq_lo: int, freq_hi: int, waveform: int, gate: bool) -> None:
        """Sets voice 1 frequency and waveform, and updates control register."""
        self.mem.write(SID_FREQ_LO1, freq_lo & 0xFF)
        self.mem.write(SID_FREQ_HI1, freq_hi & 0xFF)
        ctrl = waveform & 0xF0
        if gate:
            ctrl |= 0x01
        self.mem.write(SID_CTRL1, ctrl)

    def set_adsr(self, attack: int, decay: int, sustain: int, release: int) -> None:
        """Sets ADSR values for Voice 1 ($D405, $D406)."""
        att_dec = ((attack & 0x0F) << 4) | (decay & 0x0F)
        sust_rel = ((sustain & 0x0F) << 4) | (release & 0x0F)
        self.mem.write(SID_ATT_DEC1, att_dec)
        self.mem.write(SID_SUST_REL1, sust_rel)

    def read_random(self) -> int:
        """Reads simulated noise output from SID ($D41B)."""
        val = random.randint(0, 255)
        self.mem.write(SID_RANDOM, val)
        return val
