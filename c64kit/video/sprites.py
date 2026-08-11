# c64kit/video/sprites.py
from typing import Dict, Any, List, Tuple, Optional
from ..core.memory import C64Memory
from .vic import VICII

class HardwareSprite:
    """Represents a single C64 VIC-II hardware sprite."""

    def __init__(self, num: int):
        self.num = num
        self.x = 0
        self.y = 0
        self.color = 0
        self.enabled = False
        self.multicolor = False
        self.pointer = 0
        self.priority_foreground = True  # True = Front, False = Behind background
        self.frame = 0


class Sprites:
    """Manages the 8 C64 VIC-II hardware sprites and their simulation."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.vic = memory.vic if memory.vic else VICII(memory)
        self.sprites = [HardwareSprite(i) for i in range(8)]

    def update_from_hardware(self) -> None:
        """Synchronizes sprite states from the virtual memory/VICII registers."""
        for s in self.sprites:
            s.enabled = self.vic.is_sprite_enabled(s.num)
            s.x, s.y = self.vic.get_sprite_position(s.num)
            s.color = self.vic.get_sprite_color(s.num)
            s.pointer = self.vic.get_sprite_pointer(s.num)

            # Sprite multicolor bitmask ($D01C)
            multicolor_mask = self.vic.read(0xD01C)
            s.multicolor = bool(multicolor_mask & (1 << s.num))

            # Sprite priority ($D01B: 0 = Foreground, 1 = Background)
            priority_mask = self.vic.read(0xD01B)
            s.priority_foreground = not bool(priority_mask & (1 << s.num))

    def get_sprite_data(self, num: int) -> bytes:
        """
        Retrieves the raw 64 bytes of sprite data from memory
        based on the sprite's active pointer and current VIC bank.
        On a standard configuration, pointer value * 64 is the address offset.
        """
        s = self.sprites[num]
        # In bank 0 ($0000-$3FFF), standard pointers access (pointer * 64)
        base_addr = s.pointer * 64
        # Return 64 bytes of sprite frame data
        return bytes(self.mem.read(base_addr + i) for i in range(64))

    def check_collision(self, id1: int, id2: int) -> bool:
        """
        Calculates AABB (Axis-Aligned Bounding Box) collision between two sprites.
        A standard hardware sprite is 24x21 pixels.
        """
        self.update_from_hardware()
        s1 = self.sprites[id1]
        s2 = self.sprites[id2]

        if not s1.enabled or not s2.enabled:
            return False

        # Width is 24, Height is 21
        return (
            s1.x < s2.x + 24 and
            s1.x + 24 > s2.x and
            s1.y < s2.y + 21 and
            s1.y + 21 > s2.y
        )

    def check_sprite_background_collision(self, sprite_id: int, bg_x: int, bg_y: int, bg_w: int, bg_h: int) -> bool:
        """Calculates collision between a hardware sprite and a background bounding box."""
        self.update_from_hardware()
        s = self.sprites[sprite_id]
        if not s.enabled:
            return False

        return (
            s.x < bg_x + bg_w and
            s.x + 24 > bg_x and
            s.y < bg_y + bg_h and
            s.y + 21 > bg_y
        )
