# c64kit/core/constants.py

# ============================================================================
# SCREEN CONSTANTS
# ============================================================================
SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25
SCREEN_RAM = 0x0400
COLOR_RAM_BASE = 0xD800

# ============================================================================
# HARDWARE REGISTERS
# ============================================================================
# VIC-II
VIC_MEM = 0xD018
VIC_BORDER = 0xD020
VIC_BG = 0xD021
VIC_RASTER = 0xD012

# SID
SID_FREQ_LO1 = 0xD400
SID_FREQ_HI1 = 0xD401
SID_CTRL1 = 0xD404
SID_ATT_DEC1 = 0xD405
SID_SUST_REL1 = 0xD406
SID_VOL = 0xD418
SID_RANDOM = 0xD41B

# CIA1
CIA1_PRA = 0xDC00
CIA1_PRB = 0xDC01

# Interrupt Vectors
IRQ_VEC = 0x0314
NMI_VEC = 0x0318

# ============================================================================
# GAME SYSTEM VARIABLES
# ============================================================================
SYSTEM_TYPE = 0x028A
FIRE_DEBOUNCE_TIMER = 0x028B
SYNC_LINE_VAL = 0x028C
