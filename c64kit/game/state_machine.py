"""Game State Machine module for C64 games.

This module provides a Finite State Machine (FSM) to manage different game states
such as BOOT, SPLASH, TITLE, MENU, PLAY, PAUSE, GAMEOVER, and HIGHSCORE.
It supports transition validation, callbacks, state context sharing, and sub-states.
"""

from typing import Callable, Dict, Any, List, Optional

__all__ = ["GameStateMachine"]


class GameStateMachine:
    """Finite State Machine for C64 game states.

    Attributes:
        states: Dict mapping state names to their callbacks.
        current: The name of the current active state.
        previous: The name of the previously active state.
        transition_table: Dict mapping state names to lists of valid target states.
        context: Dict for persisting and sharing data across states.
        sub_state: Optional name of an active sub-state (e.g., overlay).
        sub_states: Dict mapping sub-state names to their callbacks.
    """

    STATES: List[str] = [
        "BOOT",
        "SPLASH",
        "TITLE",
        "MENU",
        "PLAY",
        "PAUSE",
        "GAMEOVER",
        "HIGHSCORE",
    ]

    def __init__(self) -> None:
        """Initializes the state machine with default transition rules."""
        self.states: Dict[str, Dict[str, Optional[Callable]]] = {}
        self.sub_states: Dict[str, Dict[str, Optional[Callable]]] = {}
        self.current: Optional[str] = None
        self.previous: Optional[str] = None
        self.sub_state: Optional[str] = None
        self.context: Dict[str, Any] = {}

        # Default valid transitions
        self.transition_table: Dict[str, List[str]] = {
            "BOOT": ["SPLASH", "TITLE"],
            "SPLASH": ["TITLE"],
            "TITLE": ["MENU", "PLAY"],
            "MENU": ["PLAY", "TITLE"],
            "PLAY": ["PAUSE", "GAMEOVER", "HIGHSCORE", "TITLE"],
            "PAUSE": ["PLAY", "TITLE"],
            "GAMEOVER": ["HIGHSCORE", "TITLE"],
            "HIGHSCORE": ["TITLE"],
        }

    def register_state(
        self,
        name: str,
        on_enter: Optional[Callable] = None,
        on_exit: Optional[Callable] = None,
        on_update: Optional[Callable] = None,
        on_draw: Optional[Callable] = None,
    ) -> None:
        """Registers a state with its lifecycle callbacks.

        Args:
            name: The name of the state (e.g., "PLAY").
            on_enter: Callback invoked when entering this state.
            on_exit: Callback invoked when exiting this state.
            on_update: Callback invoked during state update.
            on_draw: Callback invoked during state rendering.
        """
        self.states[name] = {
            "enter": on_enter,
            "exit": on_exit,
            "update": on_update,
            "draw": on_draw,
        }

    def register_sub_state(
        self,
        name: str,
        on_enter: Optional[Callable] = None,
        on_exit: Optional[Callable] = None,
        on_update: Optional[Callable] = None,
        on_draw: Optional[Callable] = None,
    ) -> None:
        """Registers a sub-state (e.g., pause overlay) with its lifecycle callbacks.

        Args:
            name: The name of the sub-state.
            on_enter: Callback invoked when entering this sub-state.
            on_exit: Callback invoked when exiting this sub-state.
            on_update: Callback invoked during sub-state update.
            on_draw: Callback invoked during sub-state rendering.
        """
        self.sub_states[name] = {
            "enter": on_enter,
            "exit": on_exit,
            "update": on_update,
            "draw": on_draw,
        }

    def change_state(self, new_state: str, *args: Any, **kwargs: Any) -> bool:
        """Transitions from the current state to a new state after validation.

        Args:
            new_state: The target state name.
            *args: Positional arguments to pass to the on_enter callback.
            **kwargs: Keyword arguments to pass to the on_enter callback.

        Returns:
            bool: True if transition succeeded, False otherwise.
        """
        if new_state not in self.states:
            return False

        # If there is a current state, validate the transition
        if self.current is not None:
            valid_targets = self.transition_table.get(self.current, [])
            if new_state not in valid_targets:
                return False

            # Call exit callback on the current state
            exit_cb = self.states[self.current]["exit"]
            if exit_cb:
                exit_cb()

        # Update previous and current state
        self.previous = self.current
        self.current = new_state
        self.exit_sub_state()  # Properly exit and clear any active sub-state overlay

        # Call enter callback on the new state
        enter_cb = self.states[new_state]["enter"]
        if enter_cb:
            enter_cb(*args, **kwargs)

        return True

    def enter_sub_state(self, name: str, *args: Any, **kwargs: Any) -> bool:
        """Enters a sub-state overlay.

        Args:
            name: The sub-state to enter.
            *args: Arguments for the enter callback.
            **kwargs: Keyword arguments for the enter callback.

        Returns:
            bool: True if entered successfully, False otherwise.
        """
        if name not in self.sub_states:
            return False

        if self.sub_state is not None:
            self.exit_sub_state()

        self.sub_state = name
        enter_cb = self.sub_states[name]["enter"]
        if enter_cb:
            enter_cb(*args, **kwargs)
        return True

    def exit_sub_state(self) -> None:
        """Exits the current active sub-state overlay."""
        if self.sub_state is not None:
            exit_cb = self.sub_states[self.sub_state]["exit"]
            if exit_cb:
                exit_cb()
            self.sub_state = None

    def update(self, dt: float) -> None:
        """Updates the current active state (and sub-state if active).

        Args:
            dt: Time step in seconds.
        """
        if self.sub_state is not None:
            update_cb = self.sub_states[self.sub_state]["update"]
            if update_cb:
                update_cb(dt)
                return  # Sub-state consumes update

        if self.current is not None:
            update_cb = self.states[self.current]["update"]
            if update_cb:
                update_cb(dt)

    def draw(self, screen: Any) -> None:
        """Draws the current active state and sub-state overlay if active.

        Args:
            screen: The screen/display object to draw onto.
        """
        if self.current is not None:
            draw_cb = self.states[self.current]["draw"]
            if draw_cb:
                draw_cb(screen)

        if self.sub_state is not None:
            draw_cb = self.sub_states[self.sub_state]["draw"]
            if draw_cb:
                draw_cb(screen)
