"""HUD and Score System module for C64 games.

Provides the HUDSystem class for custom overlays and the ScoreManager class
supporting BCD (Binary Coded Decimal) scores, file persistence, multi-player,
and flashing effects.
"""

import os
from typing import Dict, List, Optional, Any, Tuple, Callable
from ..core.memory import C64Memory
from ..video.colors import Colors

__all__ = ["ScoreManager", "HUDSystem"]


class ScoreManager:
    """Manages game scores and high scores using custom-width BCD logic.

    Attributes:
        mem: The C64Memory instance.
        digits: Number of digits in the score (typically 3 to 6).
        base_addr: Base address for Player 1 score in C64 Memory.
        num_bytes: Number of bytes required to hold BCD digits.
        player_scores: Dict mapping player index (1 or 2) to score value.
        high_score_addr: Memory address where the high score BCD is stored.
    """

    def __init__(self,
                 mem: C64Memory,
                 digits: int = 4,
                 base_addr: int = 0x033C) -> None:
        """Initializes the ScoreManager."""
        self.mem = mem
        self.digits = digits
        self.base_addr = base_addr
        self.num_bytes = (digits + 1) // 2

        # P1 score at base_addr, P2 score at base_addr + num_bytes
        # High score at base_addr + 2 * num_bytes
        self.high_score_addr = base_addr + 2 * self.num_bytes

        self.reset()

    def reset(self) -> None:
        """Resets current players' scores in memory."""
        # Reset memory for P1 score
        for i in range(self.num_bytes):
            self.mem.write(self.base_addr + i, 0x00)
            self.mem.write(self.base_addr + self.num_bytes + i, 0x00)

    def _int_to_bcd_bytes(self, val: int) -> List[int]:
        """Converts an integer to a list of BCD bytes."""
        max_val = (10 ** self.digits) - 1
        val = max(0, min(max_val, val))

        digits_list = []
        temp = val
        for _ in range(self.digits):
            digits_list.append(temp % 10)
            temp //= 10

        bytes_list = []
        for i in range(0, len(digits_list), 2):
            low_nibble = digits_list[i]
            high_nibble = digits_list[i + 1] if i + 1 < len(digits_list) else 0
            bytes_list.append((high_nibble << 4) | low_nibble)

        return bytes_list

    def _bcd_bytes_to_int(self, bytes_list: List[int]) -> int:
        """Converts a list of BCD bytes to an integer."""
        val = 0
        multiplier = 1
        for b in bytes_list:
            low_nibble = b & 0x0F
            high_nibble = (b >> 4) & 0x0F

            val += low_nibble * multiplier
            multiplier *= 10
            val += high_nibble * multiplier
            multiplier *= 10

        return val

    def get(self, player: int = 1) -> int:
        """Reads BCD score from memory for the specified player.

        Args:
            player: Player index (1 or 2).

        Returns:
            int: The score.
        """
        addr = self.base_addr if player == 1 else self.base_addr + self.num_bytes
        bytes_list = [self.mem.read(addr + i) for i in range(self.num_bytes)]
        return self._bcd_bytes_to_int(bytes_list)

    def set(self, value: int, player: int = 1) -> None:
        """Writes integer score as BCD into memory for the specified player.

        Args:
            player: Player index (1 or 2).
            value: Integer value to set.
        """
        addr = self.base_addr if player == 1 else self.base_addr + self.num_bytes
        bytes_list = self._int_to_bcd_bytes(value)
        for i, b in enumerate(bytes_list):
            self.mem.write(addr + i, b)

        # Sync High Score if player score exceeds it
        curr_high = self.get_high_score()
        if value > curr_high:
            self.set_high_score(value)

    def add(self, points: int, player: int = 1) -> None:
        """Adds points to a player's score.

        Args:
            points: Points to add.
            player: Player index (1 or 2).
        """
        current = self.get(player)
        self.set(current + points, player)

    def get_high_score(self) -> int:
        """Reads high score from memory."""
        bytes_list = [self.mem.read(self.high_score_addr + i) for i in range(self.num_bytes)]
        return self._bcd_bytes_to_int(bytes_list)

    def set_high_score(self, value: int) -> None:
        """Writes high score as BCD into memory."""
        bytes_list = self._int_to_bcd_bytes(value)
        for i, b in enumerate(bytes_list):
            self.mem.write(self.high_score_addr + i, b)

    def check_extra_life(self, threshold: int, previous_score: int, current_score: int) -> bool:
        """Checks if a player crossed an extra life threshold.

        Args:
            threshold: Score step to cross (e.g., 1500).
            previous_score: Player's score before.
            current_score: Player's score now.

        Returns:
            bool: True if an extra life was awarded, False otherwise.
        """
        if threshold <= 0:
            return False
        return (previous_score // threshold) < (current_score // threshold)

    def save_high_score(self, filename: str = "highscore.dat") -> None:
        """Persists the high score BCD bytes to a file.

        Args:
            filename: File path.
        """
        bytes_list = [self.mem.read(self.high_score_addr + i) for i in range(self.num_bytes)]
        with open(filename, "wb") as f:
            f.write(bytes(bytes_list))

    def load_high_score(self, filename: str = "highscore.dat") -> None:
        """Loads the high score BCD bytes from a file into C64 memory.

        Args:
            filename: File path.
        """
        if os.path.exists(filename):
            with open(filename, "rb") as f:
                data = f.read(self.num_bytes)
                for i in range(min(len(data), self.num_bytes)):
                    self.mem.write(self.high_score_addr + i, data[i])


class HUDSystem:
    """Manages Head-Up Display elements and formatting on C64.

    Attributes:
        screen: The Screen instance.
        position: 'top', 'bottom', or 'split-screen'.
        colors: Default colors list.
        elements: Dict of added HUD elements and their settings.
        flash_timers: Dict of active flash effects.
    """

    def __init__(self,
                 screen: Any,
                 position: str = "top",
                 colors: Optional[List[int]] = None) -> None:
        """Initializes HUDSystem."""
        self.screen = screen
        self.position = position
        self.colors = colors if colors is not None else [Colors.WHITE]
        self.elements: Dict[str, Dict[str, Any]] = {}
        self.flash_timers: Dict[str, float] = {}

    def add_element(self,
                    name: str,
                    type: str,
                    x: int,
                    y: int,
                    format_str: str,
                    color: int = Colors.WHITE,
                    update_fn: Optional[Callable[[], Any]] = None) -> None:
        """Adds a layout element to the HUD.

        Args:
            name: Unique name for this element.
            type: Element type ('text', 'score', 'lives', 'timer').
            x: Column position (0-39).
            y: Row position (0-24).
            format_str: String format containing placeholders (e.g., "SCORE:{:04d}").
            color: Color RAM code.
            update_fn: Optional callback returning the value to print.
        """
        # Map element y position if relative to bottom
        mapped_y = y
        if self.position == "bottom":
            mapped_y = 24 - y
        elif self.position == "split-screen" and y > 12:
            # Bottom split elements
            mapped_y = 24 - (24 - y)

        self.elements[name] = {
            "name": name,
            "type": type,
            "x": x,
            "y": mapped_y,
            "format_str": format_str,
            "color": color,
            "base_color": color,
            "value": None,
            "update_fn": update_fn,
        }

    def set_text(self, name: str, text: str) -> None:
        """Explicitly sets text value for a text element."""
        if name in self.elements:
            self.elements[name]["value"] = text

    def set_score(self, player: int, value: int) -> None:
        """Explicitly sets score value for score elements."""
        for name, elem in self.elements.items():
            if elem["type"] == "score" and name.endswith(f"p{player}"):
                elem["value"] = value
                return
        # Fallback to any score element
        for elem in self.elements.values():
            if elem["type"] == "score":
                elem["value"] = value

    def set_high_score(self, value: int) -> None:
        """Sets high score value."""
        for elem in self.elements.values():
            if elem["type"] == "high_score" or elem["name"] == "high_score":
                elem["value"] = value

    def set_lives(self, player: int, count: int, icon_char: int = 0x6C) -> None:
        """Sets lives value."""
        for name, elem in self.elements.items():
            if elem["type"] == "lives" and name.endswith(f"p{player}"):
                elem["value"] = (count, icon_char)
                return
        # Fallback to first lives element
        for elem in self.elements.values():
            if elem["type"] == "lives":
                elem["value"] = (count, icon_char)

    def set_timer(self, seconds: int) -> None:
        """Sets time value."""
        for elem in self.elements.values():
            if elem["type"] == "timer":
                elem["value"] = seconds

    def flash(self, name: str, duration_ms: float, color: int = Colors.RED) -> None:
        """Triggers a flashing effect on an element.

        Args:
            name: The HUD element name.
            duration_ms: Total duration in milliseconds.
            color: Color to blink with.
        """
        if name in self.elements:
            self.flash_timers[name] = duration_ms
            self.elements[name]["flash_color"] = color
            self.elements[name]["flash_on"] = True

    def update_flash_timers(self, dt_ms: float) -> None:
        """Ticks down active flash elements' durations.

        Args:
            dt_ms: Delta time in milliseconds.
        """
        expired = []
        for name, rem in list(self.flash_timers.items()):
            new_rem = rem - dt_ms
            if new_rem <= 0:
                expired.append(name)
                if name in self.elements:
                    self.elements[name]["color"] = self.elements[name]["base_color"]
            else:
                self.flash_timers[name] = new_rem
                if name in self.elements:
                    # Toggle flash state every 200ms
                    toggle = int(new_rem // 200) % 2 == 0
                    elem = self.elements[name]
                    elem["color"] = elem["flash_color"] if toggle else elem["base_color"]

        for name in expired:
            del self.flash_timers[name]

    def draw(self) -> None:
        """Renders all HUD layout elements to screen memory."""
        for name, elem in self.elements.items():
            # Run automatic update callback if registered
            if elem["update_fn"] is not None:
                val = elem["update_fn"]()
                elem["value"] = val

            val = elem["value"]
            if val is None:
                continue

            x, y = elem["x"], elem["y"]
            color = elem["color"]
            fmt = elem["format_str"]

            if elem["type"] == "lives":
                # Multi-character icon based drawing
                count, icon = val
                # Clear standard life area (draw spaces)
                max_display_width = len(fmt.format("")) + 5
                clear_str = " " * max_display_width
                self.screen.poke_string(x, y, clear_str, color)

                label = fmt.format("")
                self.screen.poke_string(x, y, label, color)
                for i in range(min(5, count)):
                    self.screen.poke_char(x + len(label) + i, y, icon, color)
            elif elem["type"] == "timer":
                # Convert timer to MM:SS or simply BCD display
                mins = val // 60
                secs = val % 60
                time_str = f"{mins:02d}:{secs:02d}"
                text_to_print = fmt.format(time_str)
                self.screen.poke_string(x, y, text_to_print, color)
            else:
                # Text or numeric display with options (leading zeros, thousands separator)
                if isinstance(val, int):
                    # Check if thousands separator is requested
                    if "," in fmt:
                        formatted_num = f"{val:,}"
                        text_to_print = fmt.replace("{:,}", "{}").format(formatted_num)
                    else:
                        text_to_print = fmt.format(val)
                else:
                    text_to_print = fmt.format(str(val))

                self.screen.poke_string(x, y, text_to_print, color)
