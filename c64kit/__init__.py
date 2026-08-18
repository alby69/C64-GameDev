# c64kit package
from typing import Any

__all__ = ["InvadersGame", "Colors"]

def __getattr__(name: str) -> Any:
    if name == "InvadersGame":
        from .game.invaders import InvadersGame
        return InvadersGame
    elif name == "Colors":
        from .video.colors import Colors
        return Colors
    raise AttributeError(f"module '{__name__}' has no attribute '{name}'")
