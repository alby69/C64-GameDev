# c64kit/video/colors.py

class Colors:
    """Commodore 64 Color Palette constants."""
    BLACK = 0
    WHITE = 1
    RED = 2
    CYAN = 3
    PURPLE = 4
    GREEN = 5
    BLUE = 6
    YELLOW = 7
    ORANGE = 8
    BROWN = 9
    LIGHT_RED = 10
    DARK_GREY = 11
    GREY = 12
    LIGHT_GREEN = 13
    LIGHT_BLUE = 14
    LIGHT_GREY = 15

    # Arcade green-phosphor game style
    ARCADE_GREEN = 5

    # RGB values for Pygame rendering (Commodore 64 palette)
    RGB_PALETTE = {
        0: (0, 0, 0),          # BLACK
        1: (255, 255, 255),    # WHITE
        2: (136, 0, 0),        # RED
        3: (170, 255, 238),    # CYAN
        4: (204, 68, 204),     # PURPLE
        5: (0, 204, 85),       # GREEN
        6: (0, 0, 170),        # BLUE
        7: (238, 238, 119),    # YELLOW
        8: (221, 136, 85),     # ORANGE
        9: (102, 68, 0),       # BROWN
        10: (255, 119, 119),   # LIGHT_RED
        11: (51, 51, 51),      # DARK_GREY
        12: (119, 119, 119),   # GREY
        13: (170, 255, 102),   # LIGHT_GREEN
        14: (0, 136, 255),     # LIGHT_BLUE
        15: (221, 221, 221),   # LIGHT_GREY
    }
