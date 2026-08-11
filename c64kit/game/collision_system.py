"""Collision System module for C64 games.

Provides Axis-Aligned Bounding Box (AABB) collision detection optimized with a
spatial hash grid, mask-based filtering, swept-collision handling, and callbacks.
"""

from typing import List, Dict, Optional, Tuple, Any, Callable
from dataclasses import dataclass

__all__ = ["Collision", "CollisionSystem"]


@dataclass
class Collision:
    """Represents a collision event between two objects.

    Attributes:
        id1: ID of the first colliding object.
        id2: ID of the second colliding object.
        type1: Collision type of the first object.
        type2: Collision type of the second object.
        overlap_rect: The intersection rectangle (x, y, w, h) of the collision.
    """
    id1: Any
    id2: Any
    type1: str
    type2: str
    overlap_rect: Tuple[float, float, float, float]


class CollisionSystem:
    """Spatial hash grid based AABB collision system.

    Attributes:
        cell_size: Size of each grid cell.
        grid_width: Width of the grid in units.
        grid_height: Height of the grid in units.
        objects: Dict of managed objects.
        callbacks: Dict mapping (type1, type2) pairs to lists of callbacks.
        grid: Dict mapping (cell_x, cell_y) coordinates to sets of object IDs.
    """

    COLLISION_TYPES = [
        "PLAYER",
        "ENEMY",
        "BULLET",
        "BONUS",
        "BUNKER",
        "WALL",
        "ITEM",
        "TRIGGER",
    ]

    def __init__(self,
                 cell_size: int = 8,
                 grid_width: int = 40,
                 grid_height: int = 25) -> None:
        """Initializes the CollisionSystem."""
        self.cell_size = cell_size
        self.grid_width = grid_width
        self.grid_height = grid_height
        self.objects: Dict[Any, Dict[str, Any]] = {}
        self.callbacks: Dict[Tuple[str, str], Callable[[Any, Any, Any, Any], None]] = {}
        self.grid: Dict[Tuple[int, int], List[Any]] = {}

    def _get_cells(self, x: float, y: float, w: float, h: float) -> List[Tuple[int, int]]:
        """Calculates which grid cells are intersected by the given bounding box."""
        start_cx = int(x // self.cell_size)
        end_cx = int((x + w) // self.cell_size)
        start_cy = int(y // self.cell_size)
        end_cy = int((y + h) // self.cell_size)

        cells = []
        for cx in range(start_cx, end_cx + 1):
            for cy in range(start_cy, end_cy + 1):
                cells.append((cx, cy))
        return cells

    def add_object(self,
                   obj_id: Any,
                   x: float,
                   y: float,
                   w: float,
                   h: float,
                   type: str,
                   mask: Optional[List[str]] = None) -> None:
        """Adds an object to the collision system.

        Args:
            obj_id: Unique identifier for the object.
            x: X coordinate of the bounding box.
            y: Y coordinate of the bounding box.
            w: Width of the bounding box.
            h: Height of the bounding box.
            type: Collision type (must be in COLLISION_TYPES).
            mask: Optional list of collision types this object collides with.
        """
        if type not in self.COLLISION_TYPES:
            raise ValueError(f"Invalid collision type: {type}")

        self.objects[obj_id] = {
            "id": obj_id,
            "x": x,
            "y": y,
            "w": w,
            "h": h,
            "prev_x": x,
            "prev_y": y,
            "type": type,
            "mask": mask,
        }
        self._insert_into_grid(obj_id)

    def remove_object(self, obj_id: Any) -> None:
        """Removes an object from the collision system.

        Args:
            obj_id: The ID of the object to remove.
        """
        if obj_id in self.objects:
            self._remove_from_grid(obj_id)
            del self.objects[obj_id]

    def _insert_into_grid(self, obj_id: Any) -> None:
        """Inserts an object's ID into the spatial hash grid."""
        obj = self.objects[obj_id]
        cells = self._get_cells(obj["x"], obj["y"], obj["w"], obj["h"])
        for cell in cells:
            if cell not in self.grid:
                self.grid[cell] = []
            if obj_id not in self.grid[cell]:
                self.grid[cell].append(obj_id)

    def _remove_from_grid(self, obj_id: Any) -> None:
        """Removes an object's ID from the spatial hash grid."""
        obj = self.objects[obj_id]
        cells = self._get_cells(obj["x"], obj["y"], obj["w"], obj["h"])
        for cell in cells:
            if cell in self.grid:
                if obj_id in self.grid[cell]:
                    self.grid[cell].remove(obj_id)
                if not self.grid[cell]:
                    del self.grid[cell]

    def update_position(self, obj_id: Any, x: float, y: float) -> None:
        """Updates the position of an object and updates the spatial grid.

        Args:
            obj_id: The ID of the object.
            x: New X coordinate.
            y: New Y coordinate.
        """
        if obj_id in self.objects:
            obj = self.objects[obj_id]
            self._remove_from_grid(obj_id)
            obj["prev_x"] = obj["x"]
            obj["prev_y"] = obj["y"]
            obj["x"] = x
            obj["y"] = y
            self._insert_into_grid(obj_id)

    def check_pair(self, id1: Any, id2: Any) -> Optional[Collision]:
        """Checks for bounding box collision between a specific pair of objects.

        Args:
            id1: The first object ID.
            id2: The second object ID.

        Returns:
            Optional[Collision]: A Collision instance if colliding, None otherwise.
        """
        if id1 not in self.objects or id2 not in self.objects:
            return None

        o1 = self.objects[id1]
        o2 = self.objects[id2]

        # Mask-based filtering
        if o1["mask"] is not None and o2["type"] not in o1["mask"]:
            return None
        if o2["mask"] is not None and o1["type"] not in o2["mask"]:
            return None

        # Check AABB overlap
        x1, y1, w1, h1 = o1["x"], o1["y"], o1["w"], o1["h"]
        x2, y2, w2, h2 = o2["x"], o2["y"], o2["w"], o2["h"]

        overlap_x = min(x1 + w1, x2 + w2) - max(x1, x2)
        overlap_y = min(y1 + h1, y2 + h2) - max(y1, y2)

        if overlap_x > 0 and overlap_y > 0:
            # Overlap exists
            intersection = (max(x1, x2), max(y1, y2), overlap_x, overlap_y)
            return Collision(
                id1=id1,
                id2=id2,
                type1=o1["type"],
                type2=o2["type"],
                overlap_rect=intersection,
            )

        # Swept collision detection (bullet-through-paper protection)
        # Interpolate between previous and current positions for very fast-moving objects
        dx1 = x1 - o1["prev_x"]
        dy1 = y1 - o1["prev_y"]
        dx2 = x2 - o2["prev_x"]
        dy2 = y2 - o2["prev_y"]

        # Only perform swept check if movement is larger than half of their bounding sizes
        if abs(dx1) > w1 / 2 or abs(dy1) > h1 / 2 or abs(dx2) > w2 / 2 or abs(dy2) > h2 / 2:
            steps = max(5, int(max(abs(dx1), abs(dy1), abs(dx2), abs(dy2)) / 0.5))
            for step in range(1, steps):
                t = step / steps
                ix1 = o1["prev_x"] + dx1 * t
                iy1 = o1["prev_y"] + dy1 * t
                ix2 = o2["prev_x"] + dx2 * t
                iy2 = o2["prev_y"] + dy2 * t

                overlap_x = min(ix1 + w1, ix2 + w2) - max(ix1, ix2)
                overlap_y = min(iy1 + h1, iy2 + h2) - max(iy1, iy2)

                if overlap_x > 0 and overlap_y > 0:
                    intersection = (max(ix1, ix2), max(iy1, iy2), overlap_x, overlap_y)
                    return Collision(
                        id1=id1,
                        id2=id2,
                        type1=o1["type"],
                        type2=o2["type"],
                        overlap_rect=intersection,
                    )

        return None

    def check_all(self) -> List[Collision]:
        """Checks for all collisions using spatial hash grid optimization.

        Invokes registered callbacks on matching collision types.

        Returns:
            List[Collision]: A list of all detected Collision events.
        """
        collisions = []
        checked_pairs = set()

        for cell, obj_ids in self.grid.items():
            if len(obj_ids) < 2:
                continue

            for i, id1 in enumerate(obj_ids):
                for id2 in obj_ids[i + 1:]:
                    pair_key = (id1, id2) if id1 < id2 else (id2, id1)
                    if pair_key in checked_pairs:
                        continue
                    checked_pairs.add(pair_key)

                    collision = self.check_pair(id1, id2)
                    if collision:
                        collisions.append(collision)
                        # Invoke registered callback if matching
                        self._trigger_callback(collision)

        return collisions

    def _trigger_callback(self, collision: Collision) -> None:
        """Triggers registered callbacks for a specific collision event."""
        # Try both ordering configurations
        pair1 = (collision.type1, collision.type2)
        pair2 = (collision.type2, collision.type1)

        if pair1 in self.callbacks:
            self.callbacks[pair1](
                collision.id1,
                collision.id2,
                self.objects[collision.id1],
                self.objects[collision.id2],
            )
        elif pair2 in self.callbacks:
            self.callbacks[pair2](
                collision.id2,
                collision.id1,
                self.objects[collision.id2],
                self.objects[collision.id1],
            )

    def check_point(self, x: float, y: float, type_mask: Optional[List[str]] = None) -> List[Any]:
        """Finds all object IDs intersecting a specific point coordinate.

        Args:
            x: X coordinate of the point.
            y: Y coordinate of the point.
            type_mask: Optional list of collision types to filter results.

        Returns:
            List[Any]: List of intersecting object IDs.
        """
        cell = (int(x // self.cell_size), int(y // self.cell_size))
        candidates = self.grid.get(cell, [])
        results = []

        for obj_id in candidates:
            obj = self.objects[obj_id]
            if type_mask is not None and obj["type"] not in type_mask:
                continue

            ox, oy, ow, oh = obj["x"], obj["y"], obj["w"], obj["h"]
            if ox <= x <= ox + ow and oy <= y <= oy + oh:
                results.append(obj_id)

        return results

    def set_callback(self,
                     type1: str,
                     type2: str,
                     callback: Callable[[Any, Any, Any, Any], None]) -> None:
        """Registers a callback for collisions between two specific collision types.

        Args:
            type1: The collision type of the first object.
            type2: The collision type of the second object.
            callback: Function invoked as callback(id1, id2, obj1, obj2).
        """
        if type1 not in self.COLLISION_TYPES or type2 not in self.COLLISION_TYPES:
            raise ValueError("Invalid collision types for callback registration.")
        self.callbacks[(type1, type2)] = callback
