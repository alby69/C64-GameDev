# c64kit/input/joystick.py
from ..core.constants import CIA1_PRB
from ..core.memory import C64Memory

class Joystick:
    """
    Manages reading Commodore 64 Joystick Port 2 via CIA1 Port B ($DC01).
    - Bit 2: LEFT ($04)
    - Bit 3: RIGHT ($08)
    - Bit 4: FIRE ($10)
    All bits are active low (0 = pressed, 1 = released).
    """

    def __init__(self, memory: C64Memory):
        self.mem = memory
        # Initialize with no buttons pressed (all bits high)
        self.mem.write(CIA1_PRB, 0xFF)

    def read(self) -> dict:
        """
        Reads CIA1_PRB and returns button status dict:
        {'left': bool, 'right': bool, 'fire': bool}
        """
        prb = self.mem.read(CIA1_PRB)
        left = (prb & 0x04) == 0
        right = (prb & 0x08) == 0
        fire = (prb & 0x10) == 0
        return {'left': left, 'right': right, 'fire': fire}

    def get_direction(self) -> int:
        """Returns -1 (left), 1 (right), or 0 (center) based on active joystick inputs."""
        status = self.read()
        if status['left'] and not status['right']:
            return -1
        elif status['right'] and not status['left']:
            return 1
        return 0

    def set_state(self, left: bool, right: bool, fire: bool) -> None:
        """Helper to programmatically set joystick button states in C64 memory."""
        val = 0xFF
        if left:
            val &= ~0x04
        if right:
            val &= ~0x08
        if fire:
            val &= ~0x10
        self.mem.write(CIA1_PRB, val)
