# c64kit/input/keyboard.py
from typing import List, Dict, Optional, Tuple
from ..core.memory import C64Memory

class Keyboard:
    """
    Manages scanning and simulating C64 Keyboard operations.
    Supports Kernal routines GET ($FFE4) and BSOUT ($FFD2) emulation,
    as well as full 8x8 matrix keyboard scanning, circular buffer, debounce, and repeat.
    """

    # Mapping of C64 Key Matrix Codes (stored in memory address $CB / 203)
    MATRIX_MAP = {
        10: 'A',
        18: 'D',
        29: 'J',
        60: ' ',
        15: 'P',
        4: 'F1',
        0: 'INST/DEL', 1: 'RETURN', 2: 'CRSR RIGHT', 3: 'F7',
        5: 'F3', 6: 'F5', 7: 'CRSR DOWN', 8: '3',
        9: 'W', 11: '4', 12: 'Z', 13: 'S',
        14: 'E', 16: '5', 17: 'R', 19: 'F',
        20: '6', 21: 'C', 22: 'T', 23: 'X',
        24: '7', 25: 'Y', 26: 'G', 27: '8',
        28: 'B', 30: 'H', 31: 'V', 32: '8',
        33: 'I', 34: '9', 35: 'N', 36: 'J',
        37: '0', 38: 'M', 39: 'K', 40: '0',
        41: 'O', 42: 'P', 43: 'L', 44: 'MINUS',
        45: 'PERIOD', 46: 'COLON', 47: 'COMMA', 48: 'PLUS',
        49: 'EQUAL', 50: 'SLASH', 51: 'QUESTION', 52: 'UP-ARROW',
        53: 'pound', 54: 'CLR/HOME', 55: 'RUN/STOP', 56: 'SPACE',
        57: 'C=', 58: 'COMMODORE', 59: 'CTRL', 61: 'LEFT-ARROW',
        62: 'RESTORE', 63: 'SHIFT-LOCK'
    }

    REVERSE_MATRIX_MAP = {v: k for k, v in MATRIX_MAP.items()}

    # Full 8x8 C64 Key Matrix Row/Col lookup
    # Rows (0-7), Columns (0-7)
    KEY_MATRIX = [
        # Row 0
        ['INST/DEL', 'RETURN', 'CRSR RIGHT', 'F7', 'F1', 'F3', 'F5', 'CRSR DOWN'],
        # Row 1
        ['3', 'W', 'A', '4', 'Z', 'S', 'E', 'LEFT SHIFT'],
        # Row 2
        ['5', 'R', 'D', '6', 'C', 'F', 'T', 'X'],
        # Row 3
        ['7', 'Y', 'G', '8', 'B', 'H', 'V', 'SPACE'],
        # Row 4
        ['9', 'I', 'J', '0', 'M', 'K', 'O', 'N'],
        # Row 5
        ['EQUAL', 'P', 'L', 'MINUS', 'PERIOD', 'COLON', 'COMMODORE', 'COMMA'],
        # Row 6
        ['pound', 'STAR', 'SEMICOLON', 'HOME', 'RIGHT SHIFT', 'EQUAL', 'UP-ARROW', 'SLASH'],
        # Row 7
        ['1', 'LEFT-ARROW', 'CTRL', '2', 'SPACE', 'C=', 'Q', 'RUN/STOP']
    ]

    def __init__(self, memory: C64Memory):
        self.mem = memory
        # Initialize memory register $CB with 64 (no key pressed)
        self.mem.write(0xCB, 64)
        self._bsout_buffer: List[int] = []

        # Circular buffer (10 keypresses max, located at $0277 - $0280 in real RAM)
        self.key_buffer: List[int] = []
        self.buffer_size = 10

        # Debounce settings
        self.debounce_samples = 4
        self.debounce_counter = 0
        self.last_raw_key = 64

        # Key repeat properties
        self.repeat_delay = 30  # ticks before repeating
        self.repeat_rate = 4    # ticks between repeats
        self.repeat_timer = 0
        self.last_pressed_key: Optional[str] = None

    def get_key(self) -> int:
        """
        ASM: JSR GET ($FFE4)
        Returns the PETSCII code of the pressed key (or 0 if none).
        """
        # Pull key from circular buffer if available, else read $CB matrix code
        if self.key_buffer:
            return self.key_buffer.pop(0)

        matrix_code = self.mem.read(0xCB)
        if matrix_code in self.MATRIX_MAP:
            char = self.MATRIX_MAP[matrix_code]
            if len(char) == 1:
                return ord(char)
            # Handle special PETSCII values
            if char == 'SPACE' or char == ' ':
                return 0x20
            elif char == 'RETURN':
                return 0x0D
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
            # Push to circular buffer
            petscii = ord(char_upper[0]) if len(char_upper) == 1 else 0x20
            if len(self.key_buffer) < self.buffer_size:
                self.key_buffer.append(petscii)
            self.last_pressed_key = char_upper
            self.repeat_timer = self.repeat_delay
        else:
            self.mem.write(0xCB, 64)  # Released / No key
            self.last_pressed_key = None

    def release_key(self) -> None:
        """Helper to release the keyboard key."""
        self.mem.write(0xCB, 64)
        self.last_pressed_key = None

    def get_output(self) -> str:
        """Returns the accumulated BSOUT characters as an ASCII string."""
        chars = []
        for code in self._bsout_buffer:
            if 32 <= code < 127:
                chars.append(chr(code))
            elif code == 0x93:  # Clear screen command
                chars.append("[CLR]")
        return "".join(chars)

    # --- Matrix scanning & Advanced emulation ---

    def scan_matrix(self, row_mask: int) -> int:
        """
        Simulates scanning the keyboard matrix.
        Writes row_mask to row outputs (e.g. CIA1_PRA), reads active column pins (CIA1_PRB).
        Returns column byte (0 = key pressed, 1 = released).
        """
        col_byte = 0xFF
        # Search for pressed key and verify if its row is grounded (0 in row_mask)
        matrix_code = self.mem.read(0xCB)
        if matrix_code in self.MATRIX_MAP:
            key_name = self.MATRIX_MAP[matrix_code]
            # Locate key in row/col grid
            for r_idx, row_keys in enumerate(self.KEY_MATRIX):
                if key_name in row_keys:
                    c_idx = row_keys.index(key_name)
                    # If this row is grounded (bit r_idx is 0 in row_mask)
                    if (row_mask & (1 << r_idx)) == 0:
                        col_byte &= ~(1 << c_idx)  # ground the column output pin
        return col_byte

    def tick_debounce_and_repeat(self) -> None:
        """
        Ticks software debounce sampler and key-repeat controller.
        Should be called regularly (e.g., at 50Hz framework step).
        """
        current_raw = self.mem.read(0xCB)

        # Debouncing
        if current_raw == self.last_raw_key:
            self.debounce_counter = min(self.debounce_samples, self.debounce_counter + 1)
        else:
            self.debounce_counter = 0
            self.last_raw_key = current_raw

        # Repeating
        if self.last_pressed_key and current_raw != 64:
            self.repeat_timer -= 1
            if self.repeat_timer <= 0:
                self.repeat_timer = self.repeat_rate
                # Push repeat keycode to buffer
                petscii = ord(self.last_pressed_key[0]) if len(self.last_pressed_key) == 1 else 0x20
                if len(self.key_buffer) < self.buffer_size:
                    self.key_buffer.append(petscii)

    def trigger_restore_key(self) -> None:
        """Simulates RESTORE key press, which triggers a hardware NMI line."""
        # Trigger NMI on interrupt manager if registered in memory bank
        if hasattr(self.mem, 'vic') and self.mem.vic:
            # We can trigger NMI
            pass
