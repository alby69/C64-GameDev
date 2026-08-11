"""Entity Manager module for C64 games.

Provides the base Entity class and the EntityManager class supporting spawning,
destruction, querying, updating, and drawing entity collections safely.
"""

from typing import List, Dict, Optional, Any

__all__ = ["Entity", "EntityManager"]


class Entity:
    """Base class for all game entities in the C64 framework.

    Attributes:
        id: Unique identifier.
        type: String classification (e.g., 'PLAYER', 'ENEMY').
        x: Absolute X position.
        y: Absolute Y position.
        active: Whether the entity is active and should be updated/drawn.
        properties: Arbitrary properties dictionary.
    """

    def __init__(self,
                 entity_id: int,
                 entity_type: str,
                 x: float,
                 y: float,
                 **props: Any) -> None:
        """Initializes an Entity."""
        self.id = entity_id
        self.type = entity_type
        self.x = x
        self.y = y
        self.active = True
        self.properties = props

    def update(self, dt: float) -> None:
        """Updates the entity state. To be overridden by subclasses."""
        pass

    def draw(self) -> None:
        """Renders the entity. To be overridden by subclasses."""
        pass


class EntityManager:
    """Manages spawning, updating, rendering, and safe destruction of Entity collections.

    Attributes:
        entities: Dict mapping unique entity IDs to Entity instances.
    """

    def __init__(self) -> None:
        """Initializes EntityManager."""
        self.entities: Dict[int, Entity] = {}
        self._next_id = 0

    def spawn(self, entity_type: str, x: float, y: float, **props: Any) -> int:
        """Spawns a new Entity and returns its unique ID.

        Args:
            entity_type: The string classification.
            x: Starting X coordinate.
            y: Starting Y coordinate.
            **props: Optional key-value properties.

        Returns:
            int: The assigned unique entity ID.
        """
        entity_id = self._next_id
        self._next_id += 1
        entity = Entity(entity_id, entity_type, x, y, **props)
        self.entities[entity_id] = entity
        return entity_id

    def destroy(self, entity_id: int) -> None:
        """Safely destroys an entity, freeing up references to prevent memory leaks.

        Args:
            entity_id: The ID of the entity to destroy.
        """
        if entity_id in self.entities:
            self.entities[entity_id].active = False
            del self.entities[entity_id]

    def get_all(self, entity_type: Optional[str] = None) -> List[Entity]:
        """Queries and returns all active entities, optionally filtered by type.

        Args:
            entity_type: Optional string classification to filter.

        Returns:
            List[Entity]: List of matching Entity instances.
        """
        if entity_type is None:
            return list(self.entities.values())
        return [ent for ent in self.entities.values() if ent.type == entity_type]

    def update_all(self, dt: float) -> None:
        """Updates all active entities.

        Args:
            dt: Time step in seconds.
        """
        # Create a static copy of values to avoid modification errors during updates
        for entity in list(self.entities.values()):
            if entity.active:
                entity.update(dt)

    def draw_all(self) -> None:
        """Draws all active entities."""
        for entity in list(self.entities.values()):
            if entity.active:
                entity.draw()
