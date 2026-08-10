# c64kit/game/score.py
from ..core.memory import C64Memory
from ..video.screen import Screen
from ..video.colors import Colors

class ScoreManager:
    """
    Manages game scores and player lives.
    Emulates the C64 BCD (Binary Coded Decimal) logic and registers:
    - $033C / $033D: Score BCD (low, high)
    - $033E / $033F: High Score BCD (low, high)
    - $03DB: Number of lives
    """

    def __init__(self, memory: C64Memory, screen: Screen):
        self.mem = memory
        self.screen = screen
        # Reset defaults
        self.reset()

    def reset(self) -> None:
        """Resets scores and lives in memory."""
        self.mem.write(0x033C, 0x00)  # Score low
        self.mem.write(0x033D, 0x00)  # Score high
        self.mem.write(0x033E, 0x00)  # High score low
        self.mem.write(0x033F, 0x00)  # High score high
        self.mem.write(0x03DB, 3)     # 3 lives

    @staticmethod
    def _int_to_bcd(val: int) -> tuple:
        """Converts an integer (up to 9999) to BCD low and high bytes."""
        val = max(0, min(9999, val))
        hundreds_thousands = val // 100
        ones_tens = val % 100

        high = ((hundreds_thousands // 10) << 4) | (hundreds_thousands % 10)
        low = ((ones_tens // 10) << 4) | (ones_tens % 10)
        return low, high

    @staticmethod
    def _bcd_to_int(low: int, high: int) -> int:
        """Converts BCD low and high bytes back to standard Python integer."""
        low_ones = low & 0x0F
        low_tens = (low >> 4) & 0x0F
        high_ones = high & 0x0F
        high_tens = (high >> 4) & 0x0F

        ones_tens = low_tens * 10 + low_ones
        hundreds_thousands = high_tens * 10 + high_ones
        return hundreds_thousands * 100 + ones_tens

    def get_score(self) -> int:
        """Reads current BCD score from C64 memory and returns as integer."""
        low = self.mem.read(0x033C)
        high = self.mem.read(0x033D)
        return self._bcd_to_int(low, high)

    def set_score(self, score: int) -> None:
        """Writes integer score as BCD into C64 memory."""
        low, high = self._int_to_bcd(score)
        self.mem.write(0x033C, low)
        self.mem.write(0x033D, high)

    def get_high_score(self) -> int:
        """Reads high score BCD from memory and returns integer."""
        low = self.mem.read(0x033E)
        high = self.mem.read(0x033F)
        return self._bcd_to_int(low, high)

    def set_high_score(self, high_score: int) -> None:
        """Writes integer high score as BCD into C64 memory."""
        low, high = self._int_to_bcd(high_score)
        self.mem.write(0x033E, low)
        self.mem.write(0x033F, high)

    def get_lives(self) -> int:
        """Reads remaining lives from memory."""
        return self.mem.read(0x03DB)

    def set_lives(self, lives: int) -> None:
        """Writes lives value to memory."""
        self.mem.write(0x03DB, max(0, lives))

    def add_score(self, points: int) -> None:
        """
        ASM: L0C78 — Add points.
        Converts BCD to integer, adds points, updates BCD and high score if exceeded.
        """
        current = self.get_score()
        new_score = current + points
        self.set_score(new_score)

        # Check high score update
        high = self.get_high_score()
        if new_score > high:
            self.set_high_score(new_score)

        # Extra life trigger ($0CC0) — every 1500 points (emulated simply)
        if current // 1500 < new_score // 1500:
            self.check_extra_life()

    def check_extra_life(self) -> None:
        """ASM: L0CC0 — Increments lives."""
        self.set_lives(self.get_lives() + 1)

    def draw_score(self) -> None:
        """ASM: L0C93 — Draws the current score on HUD row 0 (start around column 6)."""
        score_str = f"{self.get_score():04d}"
        self.screen.poke_string(6, 0, score_str, Colors.WHITE)

    def draw_high_score(self) -> None:
        """ASM: L17A0 — Draws high score on HUD row 0 (start around column 15)."""
        high_str = f"{self.get_high_score():04d}"
        self.screen.poke_string(15, 0, high_str, Colors.WHITE)

    def draw_lives(self) -> None:
        """
        ASM: L0A60 — Draws remaining life icons.
        Lives are displayed at top-right of HUD using square character ($6C).
        """
        # Clear lives HUD section (e.g. columns 30 to 35)
        for col in range(30, 35):
            self.screen.poke_char(col, 0, 0x20, Colors.WHITE)

        lives = self.get_lives()
        for idx in range(min(5, lives)):
            self.screen.poke_char(30 + idx, 0, 0x6C, Colors.WHITE)
