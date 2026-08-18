"""TileMap module for C64 games.

Provides the TileMap class for managing and scrolling tiled background graphics
with optional wrap-around.
"""

from typing import List, Dict, Optional, Any, Tuple
from ..video.colors import Colors

__all__ = ["TileMap"]


class TileMap:
    """Tile map class for background scrolling.

    Attributes:
        width: Width of the map in tiles.
        height: Height of the map in tiles.
        tile_width: Width of each tile in characters.
        tile_height: Height of each tile in characters.
        scroll_x: Horizontal scroll offset (in chars/pixels).
        scroll_y: Vertical scroll offset (in chars/pixels).
        wrap_around: Whether scrolling wraps around at map boundaries.
        grid: List of lists containing direct character/color values or tile IDs.
              Format: grid[ty][tx] = (char_code, color_code)
    """

    def __init__(self,
                 width: int,
                 height: int,
                 tile_width: int = 1,
                 tile_height: int = 1,
                 wrap_around: bool = False) -> None:
        """Initializes a TileMap."""
        self.width = width
        self.height = height
        self.tile_width = tile_width
        self.tile_height = tile_height
        self.scroll_x = 0
        self.scroll_y = 0
        self.wrap_around = wrap_around

        # Default grid: filled with space (0x20) and white color
        self.grid: List[List[Tuple[int, int]]] = [
            [(0x20, Colors.WHITE) for _ in range(width)]
            for _ in range(height)
        ]

    def set_tile(self, tx: int, ty: int, char: int, color: int) -> None:
        """Sets the character and color codes of a specific tile.

        Args:
            tx: X coordinate of the tile.
            ty: Y coordinate of the tile.
            char: The character/screen code.
            color: The color RAM code.
        """
        if 0 <= tx < self.width and 0 <= ty < self.height:
            self.grid[ty][tx] = (char, color)

    def scroll(self, dx: int, dy: int) -> None:
        """Adjusts the scroll offsets.

        Args:
            dx: Horizontal scroll offset delta.
            dy: Vertical scroll offset delta.
        """
        self.scroll_x += dx
        self.scroll_y += dy

        if self.wrap_around:
            max_scroll_x = self.width * self.tile_width
            max_scroll_y = self.height * self.tile_height
            if max_scroll_x > 0:
                self.scroll_x %= max_scroll_x
            if max_scroll_y > 0:
                self.scroll_y %= max_scroll_y

    def draw(self, screen: Any, offset_x: int = 0, offset_y: int = 0) -> None:
        """Renders the tilemap onto the C64 screen with scroll offsets and wrap-around.

        Args:
            screen: The Screen instance or a mock screen to write characters to.
            offset_x: Additional absolute screen X offset (character columns).
            offset_y: Additional absolute screen Y offset (character rows).
        """
        # Screen size is typically 40x25 characters on a standard C64
        screen_cols = 40
        screen_rows = 25

        # Base scroll offset
        base_sx = self.scroll_x
        base_sy = self.scroll_y

        for row in range(screen_rows):
            target_y = row + offset_y
            if not (0 <= target_y < screen_rows):
                continue

            for col in range(screen_cols):
                target_x = col + offset_x
                if not (0 <= target_x < screen_cols):
                    continue

                # Calculate corresponding position in the map
                map_char_x = col + base_sx
                map_char_y = row + base_sy

                # If wrap-around is active, we modulo the map dimensions
                if self.wrap_around:
                    map_char_x %= (self.width * self.tile_width)
                    map_char_y %= (self.height * self.tile_height)
                else:
                    # If wrap-around is disabled and we are out of boundaries, we skip or draw empty
                    if not (0 <= map_char_x < self.width * self.tile_width) or \
                       not (0 <= map_char_y < self.height * self.tile_height):
                        screen.poke_char(target_x, target_y, 0x20, Colors.BLACK)
                        continue

                # Get tile coordinates in grid
                tx = map_char_x // self.tile_width
                ty = map_char_y // self.tile_height

                char, color = self.grid[ty][tx]
                screen.poke_char(target_x, target_y, char, color)
