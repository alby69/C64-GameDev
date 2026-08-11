# c64kit/audio/sid.py
import random
from typing import Dict, Any, Optional
from ..core.constants import SID_VOL, SID_RANDOM
from ..core.memory import C64Memory

class SIDVoice:
    """Represents a single independent voice channel on the C64 SID chip."""

    def __init__(self, num: int, sid_base: int):
        self.num = num
        self.base = sid_base
        self.freq_lo = 0
        self.freq_hi = 0
        self.pw_lo = 0
        self.pw_hi = 0
        self.control = 0
        self.attack = 0
        self.decay = 0
        self.sustain = 0
        self.release = 0


class SID:
    """Wrapper and emulator class for the Commodore 64 SID 6581/8580 audio chip."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.mem.sid = self
        self.registers = bytearray(0x1D)  # Space for registers $D400 - $D41C

        # Set up 3 independent voices
        self.voices = [
            SIDVoice(0, 0xD400),
            SIDVoice(1, 0xD407),
            SIDVoice(2, 0xD40E)
        ]

        # Filter settings
        self.filter_cutoff = 0
        self.filter_resonance = 0
        self.filter_routing = 0  # Bitmask of voices filtered
        self.filter_mode = 0     # LP, BP, HP, Off
        self.master_volume = 0x0F

        self.init()

    def init(self) -> None:
        """Initializes the SID registers to standard defaults."""
        self.set_volume(0x0F)
        for i in range(3):
            self.play_tone_voice(i, 0, 0, 0, False)
            self.set_adsr_voice(i, 0x00, 0x08, 0x0A, 0x08)

    def read(self, addr: int) -> int:
        """Reads from SID registers ($D400 - $D41C)."""
        reg = addr & 0x1F
        if addr == SID_RANDOM:
            return self.read_random()
        if reg < len(self.registers):
            return self.registers[reg]
        return 0

    def write(self, addr: int, val: int) -> None:
        """Writes to SID registers, updating voice and filter structures."""
        reg = addr & 0x1F
        val &= 0xFF
        if reg < len(self.registers):
            self.registers[reg] = val

        # Map to voice structures for high-level simulation
        if 0x00 <= reg <= 0x14:
            voice_idx = reg // 7
            offset = reg % 7
            voice = self.voices[voice_idx]
            if offset == 0:
                voice.freq_lo = val
            elif offset == 1:
                voice.freq_hi = val
            elif offset == 2:
                voice.pw_lo = val
            elif offset == 3:
                voice.pw_hi = val
            elif offset == 4:
                voice.control = val
            elif offset == 5:
                voice.attack = (val >> 4) & 0x0F
                voice.decay = val & 0x0F
            elif offset == 6:
                voice.sustain = (val >> 4) & 0x0F
                voice.release = val & 0x0F

        # Filter Cutoff registers ($D415, $D416)
        elif reg == 0x15:
            self.filter_cutoff = (self.filter_cutoff & 0x07F8) | (val & 0x07)
        elif reg == 0x16:
            self.filter_cutoff = (self.filter_cutoff & 0x07) | (val << 3)

        # Filter Control ($D417)
        elif reg == 0x17:
            self.filter_resonance = (val >> 4) & 0x0F
            self.filter_routing = val & 0x0F

        # Volume / Mode ($D418)
        elif reg == 0x18:
            self.filter_mode = (val >> 4) & 0x0F
            self.master_volume = val & 0x0F

    # --- Legacy Compatibility Helpers (Voice 1 mapped) ---

    def set_volume(self, vol: int) -> None:
        """Sets the SID master volume ($D418)."""
        self.write(SID_VOL, (self.filter_mode << 4) | (vol & 0x0F))

    def play_tone(self, freq_lo: int, freq_hi: int, waveform: int, gate: bool) -> None:
        """Sets voice 1 frequency and waveform (Legacy compatible)."""
        self.play_tone_voice(0, freq_lo, freq_hi, waveform, gate)

    def set_adsr(self, attack: int, decay: int, sustain: int, release: int) -> None:
        """Sets ADSR values for Voice 1 (Legacy compatible)."""
        self.set_adsr_voice(0, attack, decay, sustain, release)

    # --- Multi-voice Helpers ---

    def play_tone_voice(self, voice_idx: int, freq_lo: int, freq_hi: int, waveform: int, gate: bool) -> None:
        """Sets the target voice frequency, waveform, and gate status."""
        if 0 <= voice_idx < 3:
            base = self.voices[voice_idx].base
            self.write(base, freq_lo & 0xFF)
            self.write(base + 1, freq_hi & 0xFF)
            ctrl = waveform & 0xF0
            if gate:
                ctrl |= 0x01
            self.write(base + 4, ctrl)

    def set_adsr_voice(self, voice_idx: int, attack: int, decay: int, sustain: int, release: int) -> None:
        """Sets ADSR envelope for the target voice."""
        if 0 <= voice_idx < 3:
            base = self.voices[voice_idx].base
            att_dec = ((attack & 0x0F) << 4) | (decay & 0x0F)
            sust_rel = ((sustain & 0x0F) << 4) | (release & 0x0F)
            self.write(base + 5, att_dec)
            self.write(base + 6, sust_rel)

    def set_pulse_width_voice(self, voice_idx: int, pw_lo: int, pw_hi: int) -> None:
        """Sets Pulse Width for the target voice."""
        if 0 <= voice_idx < 3:
            base = self.voices[voice_idx].base
            self.write(base + 2, pw_lo & 0xFF)
            self.write(base + 3, pw_hi & 0x0F)

    def read_random(self) -> int:
        """Reads simulated noise output from SID ($D41B)."""
        val = random.randint(0, 255)
        self.registers[0x1B] = val
        return val
