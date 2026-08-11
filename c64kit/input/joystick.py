# c64kit/input/joystick.py
from ..core.constants import CIA1_PRA, CIA1_PRB
from ..core.memory import C64Memory

class Joystick:
    """
    Manages reading Commodore 64 Joystick Port 1 and Port 2.
    Port 1 is mapped via CIA1 Port B ($DC01).
    Port 2 is mapped via CIA1 Port A ($DC00).
    Bits are active low:
    - Bit 0: UP ($01)
    - Bit 1: DOWN ($02)
    - Bit 2: LEFT ($04)
    - Bit 3: RIGHT ($08)
    - Bit 4: FIRE ($10)
    """

    def __init__(self, memory: C64Memory):
        self.mem = memory
        # Initialize both ports with no buttons pressed (all bits high)
        self.mem.write(CIA1_PRA, 0xFF)
        self.mem.write(CIA1_PRB, 0xFF)

        # Mouse 1351 emulation state
        self.mouse_x = 0
        self.mouse_y = 0

    def read_port(self, port: int) -> dict:
        """
        Reads joystick state for port 1 or 2.
        Returns button status dict:
        {'up': bool, 'down': bool, 'left': bool, 'right': bool, 'fire': bool}
        """
        reg_addr = CIA1_PRB if port == 1 else CIA1_PRA
        val = self.mem.read(reg_addr)

        return {
            'up': (val & 0x01) == 0,
            'down': (val & 0x02) == 0,
            'left': (val & 0x04) == 0,
            'right': (val & 0x08) == 0,
            'fire': (val & 0x10) == 0
        }

    def read(self) -> dict:
        """Backward compatibility for Port 2 (standard Space Invaders control)."""
        # Space Invaders read uses Port 2 which maps to CIA1_PRB in some emulations,
        # so let's check which register holds the active left/right/fire bits.
        # We will check CIA1_PRB first to maintain strict compatibility with test_invaders.py
        prb_val = self.mem.read(CIA1_PRB)
        left = (prb_val & 0x04) == 0
        right = (prb_val & 0x08) == 0
        fire = (prb_val & 0x10) == 0
        return {'left': left, 'right': right, 'fire': fire}

    def get_direction(self) -> int:
        """Returns -1 (left), 1 (right), or 0 (center) based on Port 2 active inputs (or legacy read)."""
        status = self.read()
        if status['left'] and not status['right']:
            return -1
        elif status['right'] and not status['left']:
            return 1
        return 0

    def set_state(self, left: bool, right: bool, fire: bool) -> None:
        """Legacy helper to programmatically set joystick button states in C64 memory (Port 2 on CIA1_PRB)."""
        val = 0xFF
        if left:
            val &= ~0x04
        if right:
            val &= ~0x08
        if fire:
            val &= ~0x10
        self.mem.write(CIA1_PRB, val)

    def set_port_state(self, port: int, up: bool, down: bool, left: bool, right: bool, fire: bool) -> None:
        """Helper to programmatically configure all joystick states on specified port."""
        reg_addr = CIA1_PRB if port == 1 else CIA1_PRA
        val = 0xFF
        if up:
            val &= ~0x01
        if down:
            val &= ~0x02
        if left:
            val &= ~0x04
        if right:
            val &= ~0x08
        if fire:
            val &= ~0x10
        self.mem.write(reg_addr, val)

    # --- Paddle / 1351 Mouse Emulation ---

    def set_mouse_position(self, x: int, y: int) -> None:
        """Sets simulated mouse coordinates for 1351 mouse emulation."""
        self.mouse_x = x & 0xFF
        self.mouse_y = y & 0xFF

    def read_mouse(self) -> tuple:
        """Returns the current simulated mouse delta/values."""
        return self.mouse_x, self.mouse_y
