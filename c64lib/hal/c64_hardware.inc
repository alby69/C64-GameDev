#ifndef C64_HARDWARE_INC
#define C64_HARDWARE_INC

; ============================================================================
; MODULE: c64_hardware.inc
; PURPOSE: Comprehensive Commodore 64 Hardware Registers and Macros
; DEPENDS: None
; ============================================================================

; ============================================================================
; CPU REGISTER & BANKING
; ============================================================================
CPU_PORT     = $01
CPU_DDR      = $00

; ============================================================================
; KERNAL & BASIC ROM ENTRIES
; ============================================================================
BSOUT        = $FFD2
GET          = $FFE4
KERNAL_IRQ   = $EA31

; ============================================================================
; VECTOR DEFINTIONS
; ============================================================================
IRQ_VEC      = $0314
NMI_VEC      = $0318

; ============================================================================
; VIC-II REGISTERS ($D000 - $D02E)
; ============================================================================
VIC_SPR0_X   = $D000
VIC_SPR0_Y   = $D001
VIC_SPR1_X   = $D002
VIC_SPR1_Y   = $D003
VIC_SPR2_X   = $D004
VIC_SPR2_Y   = $D005
VIC_SPR3_X   = $D006
VIC_SPR3_Y   = $D007
VIC_SPR4_X   = $D008
VIC_SPR4_Y   = $D009
VIC_SPR5_X   = $D00A
VIC_SPR5_Y   = $D00B
VIC_SPR6_X   = $D00C
VIC_SPR6_Y   = $D00D
VIC_SPR7_X   = $D00E
VIC_SPR7_Y   = $D00F
VIC_MSBG_X   = $D010
VIC_CTRL1    = $D011
VIC_RASTER   = $D012
VIC_LPX      = $D013
VIC_LPY      = $D014
VIC_SPR_EN   = $D015
VIC_CTRL2    = $D016
VIC_SPR_YEX  = $D017
VIC_MEM      = $D018
VIC_IRR      = $D019
VIC_IRQMASK  = $D01A
VIC_SPR_DP   = $D01B
VIC_SPR_MC   = $D01C
VIC_SPR_XEX  = $D01D
VIC_SPR_DB   = $D01E
VIC_BG_COL_B = $D01F
VIC_BORDER   = $D020
VIC_BG       = $D021
VIC_BG0      = $D021 ; Alias
VIC_BG1      = $D022
VIC_BG2      = $D023
VIC_BG3      = $D024
VIC_SPR_MCOL0= $D025
VIC_SPR_MCOL1= $D026
VIC_SPR_COL0 = $D027
VIC_SPR_COL1 = $D028
VIC_SPR_COL2 = $D029
VIC_SPR_COL3 = $D02A
VIC_SPR_COL4 = $D02B
VIC_SPR_COL5 = $D02C
VIC_SPR_COL6 = $D02D
VIC_SPR_COL7 = $D02E

; ============================================================================
; SID REGISTERS ($D400 - $D41C)
; ============================================================================
SID_FREQ_LO1 = $D400
SID_FREQ_HI1 = $D401
SID_PW_LO1   = $D402
SID_PW_HI1   = $D403
SID_CTRL1    = $D404
SID_ATT_DEC1 = $D405
SID_SUST_REL1= $D406

SID_FREQ_LO2 = $D407
SID_FREQ_HI2 = $D408
SID_PW_LO2   = $D409
SID_PW_HI2   = $D40A
SID_CTRL2    = $D40B
SID_ATT_DEC2 = $D40C
SID_SUST_REL2= $D40D

SID_FREQ_LO3 = $D40E
SID_FREQ_HI3 = $D40F
SID_PW_LO3   = $D410
SID_PW_HI3   = $D411
SID_CTRL3    = $D412
SID_ATT_DEC3 = $D413
SID_SUST_REL3= $D414

SID_FLT_CUT_LO = $D415
SID_FLT_CUT_HI = $D416
SID_FLT_CTRL   = $D417
SID_VOL        = $D418
SID_POTX       = $D419
SID_POTY       = $D41A
SID_RANDOM     = $D41B
SID_ENV3       = $D41C

; ============================================================================
; CIA1 REGISTERS ($DC00 - $DC0F)
; ============================================================================
CIA1_PRA     = $DC00
CIA1_PRB     = $DC01
CIA1_DDRA    = $DC02
CIA1_DDRB    = $DC03
CIA1_TA_LO   = $DC04
CIA1_TA_HI   = $DC05
CIA1_TB_LO   = $DC06
CIA1_TB_HI   = $DC07
CIA1_TOD_10TH= $DC08
CIA1_TOD_SEC = $DC09
CIA1_TOD_MIN = $DC0A
CIA1_TOD_HR  = $DC0B
CIA1_SDR     = $DC0C
CIA1_ICR     = $DC0D
CIA1_CRA     = $DC0E
CIA1_CRB     = $DC0F

; ============================================================================
; CIA2 REGISTERS ($DD00 - $DD0F)
; ============================================================================
CIA2_PRA     = $DD00
CIA2_PRB     = $DD01
CIA2_DDRA    = $DD02
CIA2_DDRB    = $DD03
CIA2_TA_LO   = $DD04
CIA2_TA_HI   = $DD05
CIA2_TB_LO   = $DD06
CIA2_TB_HI   = $DD07
CIA2_TOD_10TH= $DD08
CIA2_TOD_SEC = $DD09
CIA2_TOD_MIN = $DD0A
CIA2_TOD_HR  = $DD0B
CIA2_SDR     = $DD0C
CIA2_ICR     = $DD0D
CIA2_CRA     = $DD0E
CIA2_CRB     = $DD0F

; ============================================================================
; STANDARD SCREEN CONSTANTS
; ============================================================================
SCREEN_WIDTH  = 40
SCREEN_HEIGHT = 25
SCREEN_MEM    = $0400
COLOR_MEM     = $D800

; ============================================================================
; HARDWARE HELPERS & MACROS
; ============================================================================

; Macro: SAFE_SEI
; Description: Safely disables interrupts while preserving CPU status flags on stack.
#define SAFE_SEI \
    PHP : \
    SEI

; Macro: SAFE_CLI
; Description: Restores original interrupt status flags from stack.
#define SAFE_CLI \
    PLP

; Macro: SET_VIC_BANK
; Description: Sets VIC-II bank (0-3) by updating CIA2 Port A bits 0 and 1.
; Parameter: bank - Bank index (0: $0000-$3FFF, 1: $4000-$7FFF, 2: $8000-$BFFF, 3: $C000-$FFFF)
#define SET_VIC_BANK(bank) \
    LDA $DD00 : \
    AND #$FC : \
    ORA #(3 - (bank)) : \
    STA $DD00

#endif
