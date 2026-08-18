"""Sprite Engine module for C64 games.

Provides the Sprite class and SpriteEngine class supporting both character-based
and hardware sprites with dirty-rectangle tracking, background saving/restoring,
and VIC-II registers interface.
"""

from typing import Dict, List, Optional, Tuple, Any
from ..core.memory import C64Memory
from ..video.colors import Colors

__all__ = ["Sprite", "SpriteEngine"]


class Sprite:
    """Generic C64 Sprite (character-based or hardware).

    Attributes:
        x: X coordinate (character columns for 'char', pixels for 'hardware').
        y: Y coordinate (character rows for 'char', pixels for 'hardware').
        width: Width of the sprite (in chars for 'char', pixels for 'hardware').
        height: Height of the sprite (in chars for 'char', pixels for 'hardware').
        frames: Number of animation frames.
        type: 'char' or 'hardware'.
        colors: List of colors or single color value.
        collision_box: Optional bounding box relative to (x, y) as (dx, dy, w, h).
        z: Draw order priority (higher is drawn on top).
        active: Whether the sprite is active and should be updated/drawn.
        current_frame: The current frame index.
        char_data: List of list of character codes for 'char' sprite frames.
                  Format: list of frames, where each frame is a flat list of length width*height.
    """

    def __init__(self,
                 x: int,
                 y: int,
                 width: int,
                 height: int,
                 frames: int = 1,
                 type: str = "char",
                 colors: Any = None,
                 collision_box: Optional[Tuple[int, int, int, int]] = None,
                 z: int = 0,
                 active: bool = True) -> None:
        """Initializes a Sprite."""
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.frames = frames
        self.type = type
        self.colors = colors if colors is not None else [Colors.WHITE]
        self.collision_box = collision_box if collision_box is not None else (0, 0, width, height)
        self.z = z
        self.active = active
        self.current_frame = 0

        # Char data for each frame: list of frames, each is a list of screen codes of size width*height
        self.char_data: List[List[int]] = [[] for _ in range(frames)]

    def set_frame_data(self, frame_idx: int, data: List[int]) -> None:
        """Sets the character data for a specific animation frame (for 'char' type).

        Args:
            frame_idx: The frame index (0-based).
            data: List of screen codes.
        """
        if 0 <= frame_idx < self.frames:
            self.char_data[frame_idx] = data

    def get_aabb(self) -> Tuple[int, int, int, int]:
        """Gets the Axis-Aligned Bounding Box (AABB) of the sprite in absolute coordinates.

        Returns:
            Tuple[int, int, int, int]: (x, y, width, height)
        """
        dx, dy, w, h = self.collision_box
        return self.x + dx, self.y + dy, w, h


class SpriteEngine:
    """Manages sprite lifecycles and rendering with dirty-rectangle optimization.

    Attributes:
        mem: The C64Memory instance.
        screen: The Screen instance.
        max_sprites: Maximum allowed active sprites.
        sprites: Dict of active sprites by ID.
        bg_buffers: Saved background character and color RAM data for restoring.
    """

    def __init__(self, mem: C64Memory, screen: Any, max_sprites: int = 32) -> None:
        """Initializes the SpriteEngine."""
        self.mem = mem
        self.screen = screen
        self.max_sprites = max_sprites
        self.sprites: Dict[int, Sprite] = {}
        self.bg_buffers: Dict[int, Dict[str, Any]] = {}
        self._next_id = 0

    def add(self, sprite: Sprite) -> int:
        """Adds a sprite to the engine and returns its assigned ID.

        Args:
            sprite: The Sprite instance to add.

        Returns:
            int: The assigned sprite ID.
        """
        if len(self.sprites) >= self.max_sprites:
            raise RuntimeError("Maximum sprite count reached.")
        sprite_id = self._next_id
        self._next_id += 1
        self.sprites[sprite_id] = sprite
        return sprite_id

    def remove(self, sprite_id: int) -> None:
        """Removes a sprite by ID and restores its background if drawn.

        Args:
            sprite_id: The ID of the sprite to remove.
        """
        if sprite_id in self.sprites:
            self._restore_background(sprite_id)
            del self.sprites[sprite_id]
            if sprite_id in self.bg_buffers:
                del self.bg_buffers[sprite_id]

    def move(self, sprite_id: int, dx: int, dy: int) -> None:
        """Moves a sprite by delta offsets.

        Args:
            sprite_id: The ID of the sprite.
            dx: Horizontal delta.
            dy: Vertical delta.
        """
        if sprite_id in self.sprites:
            sprite = self.sprites[sprite_id]
            # Restore background first
            self._restore_background(sprite_id)
            sprite.x += dx
            sprite.y += dy

    def animate(self, sprite_id: int, frame: int) -> None:
        """Sets the current animation frame of a sprite.

        Args:
            sprite_id: The ID of the sprite.
            frame: The frame index.
        """
        if sprite_id in self.sprites:
            sprite = self.sprites[sprite_id]
            if 0 <= frame < sprite.frames:
                if sprite.current_frame != frame:
                    self._restore_background(sprite_id)
                    sprite.current_frame = frame

    def check_collision(self, id1: int, id2: int) -> bool:
        """Checks for bounding box collision between two sprites.

        Args:
            id1: The first sprite ID.
            id2: The second sprite ID.

        Returns:
            bool: True if they overlap, False otherwise.
        """
        if id1 not in self.sprites or id2 not in self.sprites:
            return False
        s1 = self.sprites[id1]
        s2 = self.sprites[id2]
        if not s1.active or not s2.active:
            return False

        x1, y1, w1, h1 = s1.get_aabb()
        x2, y2, w2, h2 = s2.get_aabb()

        return (x1 < x2 + w2 and
                x1 + w1 > x2 and
                y1 < y2 + h2 and
                y1 + h1 > y2)

    def _save_background(self, sprite_id: int, sprite: Sprite) -> None:
        """Saves background screen characters and colors before drawing a char sprite."""
        if sprite.type != "char":
            return

        saved_chars = []
        saved_colors = []
        screen_ram_base = 0x0400
        color_ram_base = 0xD800

        for row in range(sprite.height):
            y_abs = sprite.y + row
            if 0 <= y_abs < 25:
                for col in range(sprite.width):
                    x_abs = sprite.x + col
                    if 0 <= x_abs < 40:
                        offset = y_abs * 40 + x_abs
                        saved_chars.append(self.mem.read(screen_ram_base + offset))
                        saved_colors.append(self.mem.read(color_ram_base + offset))
                    else:
                        saved_chars.append(0x20)
                        saved_colors.append(Colors.BLACK)
            else:
                for _ in range(sprite.width):
                    saved_chars.append(0x20)
                    saved_colors.append(Colors.BLACK)

        self.bg_buffers[sprite_id] = {
            "x": sprite.x,
            "y": sprite.y,
            "width": sprite.width,
            "height": sprite.height,
            "chars": saved_chars,
            "colors": saved_colors
        }

    def _restore_background(self, sprite_id: int) -> None:
        """Restores saved background screen characters and colors for a char sprite."""
        if sprite_id not in self.bg_buffers:
            return

        bg = self.bg_buffers[sprite_id]
        screen_ram_base = 0x0400
        color_ram_base = 0xD800
        idx = 0

        for row in range(bg["height"]):
            y_abs = bg["y"] + row
            if 0 <= y_abs < 25:
                for col in range(bg["width"]):
                    x_abs = bg["x"] + col
                    if 0 <= x_abs < 40:
                        offset = y_abs * 40 + x_abs
                        self.mem.write(screen_ram_base + offset, bg["chars"][idx])
                        self.mem.write(color_ram_base + offset, bg["colors"][idx])
                    idx += 1
            else:
                idx += bg["width"]

        del self.bg_buffers[sprite_id]

    def clear_all(self) -> None:
        """Restores backgrounds for all sprites."""
        # Restore backgrounds in reverse order of drawing
        for sprite_id in sorted(self.bg_buffers.keys(), reverse=True):
            self._restore_background(sprite_id)

    def draw_all(self) -> None:
        """Renders all active sprites. Handles dirty background saving/restoring and VIC-II hardware sprite registers."""
        # Sort active sprites by Z-index for drawing priority
        active_sprites = [
            (sid, s) for sid, s in self.sprites.items() if s.active
        ]
        active_sprites.sort(key=lambda item: item[1].z)

        hw_sprite_count = 0

        for sprite_id, sprite in active_sprites:
            if sprite.type == "char":
                # Save the new background before we write over it
                self._save_background(sprite_id, sprite)

                # Render char-sprite to screen memory with clipping
                frame_idx = sprite.current_frame
                if frame_idx >= len(sprite.char_data) or not sprite.char_data[frame_idx]:
                    continue

                data = sprite.char_data[frame_idx]
                color = sprite.colors[0] if isinstance(sprite.colors, list) else sprite.colors

                screen_ram_base = 0x0400
                color_ram_base = 0xD800

                for row in range(sprite.height):
                    y_abs = sprite.y + row
                    if 0 <= y_abs < 25:
                        for col in range(sprite.width):
                            x_abs = sprite.x + col
                            if 0 <= x_abs < 40:
                                offset = y_abs * 40 + x_abs
                                char_code = data[row * sprite.width + col]
                                self.mem.write(screen_ram_base + offset, char_code)
                                self.mem.write(color_ram_base + offset, color)

            elif sprite.type == "hardware":
                # Manage C64 VIC-II Hardware sprite registers
                # Only 8 hardware sprites exist (0-7)
                if hw_sprite_count < 8:
                    idx = hw_sprite_count
                    hw_sprite_count += 1

                    # Enable sprite: $D015 register bit setting
                    d015_val = self.mem.read(0xD015)
                    self.mem.write(0xD015, d015_val | (1 << idx))

                    # Position: $D000 + 2*idx (X), $D001 + 2*idx (Y)
                    # MSB of X is in $D010
                    x_pixel = max(0, min(511, sprite.x))
                    y_pixel = max(0, min(255, sprite.y))

                    self.mem.write(0xD000 + 2 * idx, x_pixel & 0xFF)
                    self.mem.write(0xD001 + 2 * idx, y_pixel & 0xFF)

                    # Update MSB of X
                    d010_val = self.mem.read(0xD010)
                    if x_pixel > 255:
                        self.mem.write(0xD010, d010_val | (1 << idx))
                    else:
                        self.mem.write(0xD010, d010_val & ~(1 << idx))

                    # Color: $D027 + idx
                    color = sprite.colors[0] if isinstance(sprite.colors, list) else sprite.colors
                    self.mem.write(0xD027 + idx, color)
