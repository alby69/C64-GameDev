# c64kit/input/keyboard.py
from ..core.memory import C64Memory

class Keyboard:
    """
    Manages scanning and simulating C64 Keyboard operations.
    Supports Kernal routines GET ($FFE4) and BSOUT ($FFD2) emulation.
    """

    # Mapping of C64 Key Matrix Codes (stored in memory address $CB / 203)
    MATRIX_MAP = {
        10: 'A',
        18: 'D',
        29: 'J',
        60: ' ',
        15: 'P',
        4: 'F1'
    }

    REVERSE_MATRIX_MAP = {v: k for k, v in MATRIX_MAP.items()}

    def __init__(self, memory: C64Memory):
        self.mem = memory
        # Initialize memory register $CB with 64 (no key pressed)
        self.mem.write(0xCB, 64)
        self._bsout_buffer = []

    def get_key(self) -> int:
        """
        ASM: JSR GET ($FFE4)
        Returns the PETSCII code of the pressed key (or 0 if none).
        """
        matrix_code = self.mem.read(0xCB)
        if matrix_code in self.MATRIX_MAP:
            char = self.MATRIX_MAP[matrix_code]
            # Convert char to PETSCII
            return ord(char)
        return 0

    def bsout(self, char: int) -> None:
        """
        ASM: JSR BSOUT ($FFD2)
        Appends the output character to an internal buffer for logging/display.
        """
        self._bsout_buffer.append(char & 0xFF)

    def wait_key(self) -> int:
        """
        ASM: L0436/L043B loop.
        Blocks/simulates busy-waiting until a key is pressed.
        """
        # Programmatic simulation: we read the current key, if 0, we simulate pressing 'Space' (60)
        key = self.get_key()
        if key == 0:
            self.press_key(' ')
            key = self.get_key()
        return key

    def press_key(self, char: str) -> None:
        """Helper to programmatically press a key by writing its matrix code to address $CB."""
        char_upper = char.upper()
        if char_upper in self.REVERSE_MATRIX_MAP:
            code = self.REVERSE_MATRIX_MAP[char_upper]
            self.mem.write(0xCB, code)
        else:
            self.mem.write(0xCB, 64)  # Released / No key

    def release_key(self) -> None:
        """Helper to release the keyboard key."""
        self.mem.write(0xCB, 64)

    def get_output(self) -> str:
        """Returns the accumulated BSOUT characters as an ASCII string."""
        chars = []
        for code in self._bsout_buffer:
            if 32 <= code < 127:
                chars.append(chr(code))
            elif code == 0x93:  # Clear screen command
                chars.append("[CLR]")
        return "".join(chars)
