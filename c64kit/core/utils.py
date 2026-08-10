# c64kit/core/utils.py

def ascii_to_screen_code(char: str) -> int:
    """
    Converts a single ASCII character to its C64 Screen Code equivalent.
    - 'A'-'Z' maps to 1-26
    - 'a'-'z' maps to 1-26 (standard C64 upper/graphics) or 97-122
    - '0'-'9' maps to 48-57
    - Special chars are mapped to their screen code values.
    """
    if not char:
        return 0x20
    val = ord(char)
    if 65 <= val <= 90:    # 'A'-'Z'
        return val - 64
    elif 97 <= val <= 122:  # 'a'-'z' (convert to uppercase screen code)
        return val - 96
    elif 48 <= val <= 57:  # '0'-'9'
        return val
    elif char == ' ':
        return 0x20
    elif char == '*':
        return 0x2A
    elif char == '-':
        return 0x2D
    elif char == '.':
        return 0x2E
    elif char == '?':
        return 0x3F
    elif char == ':':
        return 0x3A
    return val

def screen_code_to_ascii(code: int) -> str:
    """Converts a C64 Screen Code to a printable ASCII character."""
    code &= 0xFF
    if 1 <= code <= 26:
        return chr(code + 64)   # 'A'-'Z'
    elif 48 <= code <= 57:
        return chr(code)        # '0'-'9'
    elif code == 0x20:
        return ' '
    elif code == 0x2A:
        return '*'
    elif code == 0x2D:
        return '-'
    elif code == 0x2E:
        return '.'
    elif code == 0x3F:
        return '?'
    elif code == 0x3A:
        return ':'
    return chr(code) if 32 <= code < 127 else '?'

def ascii_to_petscii(char: str) -> int:
    """Converts an ASCII character to PETSCII byte representation."""
    if not char:
        return 0
    val = ord(char)
    # Convert lowercase input to uppercase PETSCII
    if 97 <= val <= 122:
        return val - 32
    return val
