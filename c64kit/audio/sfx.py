# c64kit/audio/sfx.py
from .sid import SID

class SoundEffects:
    """High-level wrapper for Commodore 64 Space Invaders sound effects."""

    FREQ_TABLE = bytes([
        0x00, 0x01, 0x00, 0x01, 0x50, 0x00, 0x50, 0x01,
        0x00, 0x01, 0x50, 0x00, 0x00, 0x01, 0x00, 0x00
    ])
    FREQ_TABLE2 = bytes([0x13, 0x03, 0x0F, 0x12, 0x05])
    FREQ_EFFECT = bytes([
        0x00, 0x00, 0x7A, 0x68, 0x56, 0x44, 0x32, 0x28,
        0x10, 0x15, 0x28, 0x36, 0x40, 0x48, 0x4D, 0x50
    ])

    def __init__(self, sid: SID):
        self.sid = sid

    def invader_step(self, step_counter: int, ufo_hit: bool = False) -> None:
        """
        ASM: L0550 — Invader step sound.
        Uses step_counter to offset in FREQ_TABLE.
        """
        idx = step_counter & 0x0F
        freq_lo = self.FREQ_TABLE[idx]
        if ufo_hit:
            freq_lo = (freq_lo + 0x50) & 0xFF

        self.sid.play_tone(freq_lo, 0x00, 0x80, gate=True)
        # Emulate pulse gate off
        self.sid.play_tone(freq_lo, 0x00, 0x80, gate=False)

    def player_shoot(self, shoot_timer: int) -> None:
        """
        ASM: L16EA — Player laser shoot sound effect.
         shoot_timer is decreased externally (equivalent to M02A4).
        """
        if shoot_timer <= 0:
            return
        idx = shoot_timer & 0x0F
        freq_lo = self.FREQ_EFFECT[idx]
        self.sid.play_tone(freq_lo, 0x00, 0x80, gate=True)
        self.sid.play_tone(freq_lo, 0x00, 0x80, gate=False)

    def explosion(self, explosion_timer: int) -> None:
        """
        ASM: L16E0 — Explosion sound effect.
        explosion_timer is index in FREQ_EFFECT (equivalent to M03D9).
        """
        idx = explosion_timer & 0x0F
        freq_lo = self.FREQ_EFFECT[idx]
        self.sid.play_tone(freq_lo, 0x00, 0x80, gate=True)
        self.sid.play_tone(freq_lo, 0x00, 0x80, gate=False)

    def ufo_sound(self, ufo_timer: int) -> None:
        """
        ASM: L1652 — UFO/mystery tone sound loop.
        ufo_timer corresponds to M02A2 index.
        """
        idx = ufo_timer % len(self.FREQ_TABLE2)
        freq_lo = self.FREQ_TABLE2[idx]
        self.sid.play_tone(freq_lo, 0x00, 0x40, gate=True)  # Pulsetone
