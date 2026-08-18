# c64kit/input/input_manager.py
from typing import Dict, List, Set, Any, Optional
from .joystick import Joystick
from .keyboard import Keyboard

class ActionState:
    """Tracks state and transition lifecycles of a mapped game action."""

    def __init__(self):
        self.pressed = False   # True only on the frame the action was triggered
        self.held = False      # True while the action button is continuously held down
        self.released = False  # True only on the frame the action was released
        self._last_state = False


class InputManager:
    """
    Unified input management layer for C64 games.
    Aggregates inputs from keyboard matrices and joystick ports,
    supporting action mappings, frame-per-frame states, and combo/sequence detection.
    """

    def __init__(self, joystick: Joystick, keyboard: Keyboard):
        self.joystick = joystick
        self.keyboard = keyboard
        self.bindings: Dict[str, List[str]] = {}
        self.actions: Dict[str, ActionState] = {}
        self.history: List[str] = []
        self.history_max = 20

    def bind_action(self, action_name: str, inputs: List[str]) -> None:
        """
        Binds a custom named action to a list of physical keys or joystick inputs.
        e.g., bind_action("MOVE_LEFT", ["A", "JOY2_LEFT", "CRSR LEFT"])
        """
        self.bindings[action_name] = [inp.upper() for inp in inputs]
        self.actions[action_name] = ActionState()

    def update(self) -> None:
        """
        Calculates frame-per-frame state transitions for all registered actions.
        Should be called once per frame interrupt or game loop iteration.
        """
        # Read current joystick states
        joy1 = self.joystick.read_port(1)
        joy2 = self.joystick.read_port(2)
        # Check standard keyboard matrix state code
        kbd_char_code = self.keyboard.mem.read(0xCB)
        kbd_char = Keyboard.MATRIX_MAP.get(kbd_char_code, "").upper()

        for action_name, inputs in self.bindings.items():
            state = self.actions[action_name]
            is_active = False

            # Check if any bound input is active
            for inp in inputs:
                # Keyboard keys
                if inp == kbd_char or (inp == "SPACE" and kbd_char == " "):
                    is_active = True
                    break

                # Joystick 2
                elif inp == "JOY2_LEFT" and joy2['left']:
                    is_active = True
                    break
                elif inp == "JOY2_RIGHT" and joy2['right']:
                    is_active = True
                    break
                elif inp == "JOY2_UP" and joy2['up']:
                    is_active = True
                    break
                elif inp == "JOY2_DOWN" and joy2['down']:
                    is_active = True
                    break
                elif inp == "JOY2_FIRE" and joy2['fire']:
                    is_active = True
                    break

                # Joystick 1
                elif inp == "JOY1_LEFT" and joy1['left']:
                    is_active = True
                    break
                elif inp == "JOY1_RIGHT" and joy1['right']:
                    is_active = True
                    break
                elif inp == "JOY1_UP" and joy1['up']:
                    is_active = True
                    break
                elif inp == "JOY1_DOWN" and joy1['down']:
                    is_active = True
                    break
                elif inp == "JOY1_FIRE" and joy1['fire']:
                    is_active = True
                    break

            # Process state transitions
            state.held = is_active
            state.pressed = is_active and not state._last_state
            state.released = not is_active and state._last_state
            state._last_state = is_active

            # Append to input sequence history on initial press
            if state.pressed:
                self.history.append(action_name)
                if len(self.history) > self.history_max:
                    self.history.pop(0)

    def is_pressed(self, action_name: str) -> bool:
        """Returns True if the action was triggered on this exact frame."""
        return self.actions.get(action_name).pressed if action_name in self.actions else False

    def is_held(self, action_name: str) -> bool:
        """Returns True if the action is currently being held down."""
        return self.actions.get(action_name).held if action_name in self.actions else False

    def is_released(self, action_name: str) -> bool:
        """Returns True if the action was released on this exact frame."""
        return self.actions.get(action_name).released if action_name in self.actions else False

    def check_combo(self, combo: List[str]) -> bool:
        """
        Checks if the recent history matches a specific input action combo.
        e.g., check_combo(["UP", "UP", "DOWN", "DOWN"])
        """
        if len(self.history) < len(combo):
            return False
        # Compare slice of history matching combo length
        return self.history[-len(combo):] == combo
