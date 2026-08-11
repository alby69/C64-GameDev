"""Level Manager module for C64 games.

Provides the LevelConfig dataclass and the LevelManager class supporting wave and
level loading, progression, and binary serialization/deserialization.
"""

from typing import List, Tuple, Dict, Optional, Any
from dataclasses import dataclass, field
import struct

__all__ = ["LevelConfig", "LevelManager"]


@dataclass
class LevelConfig:
    """Configuration class for game levels/waves.

    Attributes:
        name: Name of the level.
        enemy_layout: List of tuples representing (x, y, type) of enemies.
        player_start: Tuple representing (x, y) start coordinates for the player.
        bunker_positions: List of tuples representing (x, y) bunker coordinates.
        bonus_frequency: Frequency of spawning bonus entities (e.g., in frames).
        speed_curve: List of delays or speeds representing progression as waves advance.
        palette: List of VIC-II color values mapping to types.
    """
    name: str
    enemy_layout: List[Tuple[int, int, int]] = field(default_factory=list)
    player_start: Tuple[int, int] = (20, 21)
    bunker_positions: List[Tuple[int, int]] = field(default_factory=list)
    bonus_frequency: int = 500
    speed_curve: List[int] = field(default_factory=list)
    palette: List[int] = field(default_factory=list)


class LevelManager:
    """Manages level configurations, waves, and serializes configs for C64 assembly.

    Attributes:
        levels: List of LevelConfig instances.
        current_level_idx: Current active level index.
    """

    def __init__(self) -> None:
        """Initializes LevelManager."""
        self.levels: List[LevelConfig] = []
        self.current_level_idx: int = 0

    def add_level(self, config: LevelConfig) -> None:
        """Adds a level configuration to the manager.

        Args:
            config: The LevelConfig to add.
        """
        self.levels.append(config)

    def load_level(self, config: LevelConfig) -> None:
        """Loads a specific level configuration directly and sets as current.

        Args:
            config: The LevelConfig to load.
        """
        # If already in registered list, set index. Otherwise, add and set.
        if config in self.levels:
            self.current_level_idx = self.levels.index(config)
        else:
            self.levels.append(config)
            self.current_level_idx = len(self.levels) - 1

    def next_wave(self) -> LevelConfig:
        """Advances to the next level/wave and returns its configuration.

        Wrap-around to index 0 if the end is reached.

        Returns:
            LevelConfig: The next LevelConfig.
        """
        if not self.levels:
            raise ValueError("No level configurations registered.")
        self.current_level_idx = (self.current_level_idx + 1) % len(self.levels)
        return self.get_current()

    def get_current(self) -> LevelConfig:
        """Gets the current active level configuration.

        Returns:
            LevelConfig: The current active LevelConfig.
        """
        if not self.levels:
            raise ValueError("No level configurations registered.")
        return self.levels[self.current_level_idx]

    def serialize(self, config: Optional[LevelConfig] = None) -> bytes:
        """Serializes a LevelConfig to a C64 assembly compatible binary format.

        Format definition:
            - Name length: 1 byte
            - Name: length bytes (ASCII)
            - Player start: 2 bytes (x, y)
            - Bonus frequency: 2 bytes (unsigned short, little-endian)
            - Enemy count: 1 byte
            - Enemy layout: count * 3 bytes (x, y, type)
            - Bunker count: 1 byte
            - Bunker layout: count * 2 bytes (x, y)
            - Speed curve count: 1 byte
            - Speed curve: count * 1 byte (delays)
            - Palette count: 1 byte
            - Palette: count * 1 byte (colors)

        Args:
            config: Optional config to serialize (defaults to current).

        Returns:
            bytes: The serialized byte array.
        """
        if config is None:
            config = self.get_current()

        # Name serialization
        name_bytes = config.name.encode("ascii", errors="ignore")
        name_len = len(name_bytes) & 0xFF

        serialized = bytearray()
        serialized.append(name_len)
        serialized.extend(name_bytes)

        # Player start (x, y)
        serialized.append(config.player_start[0] & 0xFF)
        serialized.append(config.player_start[1] & 0xFF)

        # Bonus frequency (2 bytes, little-endian for 6502 compat)
        serialized.extend(struct.pack("<H", config.bonus_frequency))

        # Enemy layout
        enemies_count = len(config.enemy_layout) & 0xFF
        serialized.append(enemies_count)
        for x, y, etype in config.enemy_layout:
            serialized.append(x & 0xFF)
            serialized.append(y & 0xFF)
            serialized.append(etype & 0xFF)

        # Bunker positions
        bunkers_count = len(config.bunker_positions) & 0xFF
        serialized.append(bunkers_count)
        for bx, by in config.bunker_positions:
            serialized.append(bx & 0xFF)
            serialized.append(by & 0xFF)

        # Speed curve
        speeds_count = len(config.speed_curve) & 0xFF
        serialized.append(speeds_count)
        for speed in config.speed_curve:
            serialized.append(speed & 0xFF)

        # Palette
        palette_count = len(config.palette) & 0xFF
        serialized.append(palette_count)
        for color in config.palette:
            serialized.append(color & 0xFF)

        return bytes(serialized)

    def deserialize(self, data: bytes) -> LevelConfig:
        """Deserializes a binary byte array back into a LevelConfig.

        Args:
            data: Serialized level bytes.

        Returns:
            LevelConfig: The reconstructed LevelConfig.
        """
        offset = 0

        # Name
        name_len = data[offset]
        offset += 1
        name = data[offset : offset + name_len].decode("ascii")
        offset += name_len

        # Player start
        px = data[offset]
        py = data[offset + 1]
        offset += 2
        player_start = (px, py)

        # Bonus frequency
        bonus_frequency = struct.unpack("<H", data[offset : offset + 2])[0]
        offset += 2

        # Enemy layout
        enemy_layout = []
        enemies_count = data[offset]
        offset += 1
        for _ in range(enemies_count):
            ex = data[offset]
            ey = data[offset + 1]
            etype = data[offset + 2]
            enemy_layout.append((ex, ey, etype))
            offset += 3

        # Bunkers
        bunker_positions = []
        bunkers_count = data[offset]
        offset += 1
        for _ in range(bunkers_count):
            bx = data[offset]
            by = data[offset + 1]
            bunker_positions.append((bx, by))
            offset += 2

        # Speed curve
        speed_curve = []
        speeds_count = data[offset]
        offset += 1
        for _ in range(speeds_count):
            speed_curve.append(data[offset])
            offset += 1

        # Palette
        palette = []
        palette_count = data[offset]
        offset += 1
        for _ in range(palette_count):
            palette.append(data[offset])
            offset += 1

        return LevelConfig(
            name=name,
            enemy_layout=enemy_layout,
            player_start=player_start,
            bunker_positions=bunker_positions,
            bonus_frequency=bonus_frequency,
            speed_curve=speed_curve,
            palette=palette,
        )
