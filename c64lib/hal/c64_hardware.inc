; ============================================================================
; MODULE: c64_hardware.inc
; PURPOSE: Complete C64 hardware register definitions and utility macros
; DEPENDS: None
; CLOBBER: None (macros specify their clobber behavior in documentation)
; ============================================================================

; ============================================================================
; VIC-II Registers ($D000 - $D02E)
; ============================================================================
VIC_SPR0_X    = $D000
VIC_SPR0_Y    = $D001
VIC_SPR1_X    = $D002
VIC_SPR1_Y    = $D003
VIC_SPR2_X    = $D004
VIC_SPR2_Y    = $D005
VIC_SPR3_X    = $D006
VIC_SPR3_Y    = $D007
VIC_SPR4_X    = $D008
VIC_SPR4_Y    = $D009
VIC_SPR5_X    = $D00A
VIC_SPR5_Y    = $D00B
VIC_SPR6_X    = $D00C
VIC_SPR6_Y    = $D00D
VIC_SPR7_X    = $D00E
VIC_SPR7_Y    = $D00F
VIC_MSBG_X    = $D010
VIC_CTRL1     = $D011
VIC_RASTER    = $D012
VIC_LPX       = $D013
VIC_LPY       = $D014
VIC_SPR_EN    = $D015
VIC_CTRL2     = $D016
VIC_SPR_YEX   = $D017
VIC_MEM       = $D018
VIC_IRR       = $D019
VIC_IRQMASK   = $D01A
VIC_SPR_PRIO  = $D01B
VIC_SPR_MCOL  = $D01C
VIC_SPR_XEX   = $D01D
VIC_SPR_DP    = $D01E
VIC_SPR_DB    = $D01F
VIC_BORDER    = $D020
VIC_BG0       = $D021
VIC_BG1       = $D022
VIC_BG2       = $D023
VIC_BG3       = $D024
VIC_SPR_MCOL0 = $D025
VIC_SPR_MCOL1 = $D026
VIC_SPR0_COL  = $D027
VIC_SPR1_COL  = $D028
VIC_SPR2_COL  = $D029
VIC_SPR3_COL  = $D02A
VIC_SPR4_COL  = $D02B
VIC_SPR5_COL  = $D02C
VIC_SPR6_COL  = $D02D
VIC_SPR7_COL  = $D02E

; ============================================================================
; SID Registers ($D400 - $D41C)
; ============================================================================
SID_V1_FREQ_LO = $D400
SID_V1_FREQ_HI = $D401
SID_V1_PW_LO   = $D402
SID_V1_PW_HI   = $D403
SID_V1_CTRL    = $D404
SID_V1_ATT_DEC = $D405
SID_V1_SUST_REL = $D406

SID_V2_FREQ_LO = $D407
SID_V2_FREQ_HI = $D408
SID_V2_PW_LO   = $D409
SID_V2_PW_HI   = $D40A
SID_V2_CTRL    = $D40B
SID_V2_ATT_DEC = $D40C
SID_V2_SUST_REL = $D40D

SID_V3_FREQ_LO = $D40E
SID_V3_FREQ_HI = $D40F
SID_V3_PW_LO   = $D410
SID_V3_PW_HI   = $D411
SID_V3_CTRL    = $D412
SID_V3_ATT_DEC = $D413
SID_V3_SUST_REL = $D414

SID_FILTER_CUTOFF_LO = $D415
SID_FILTER_CUTOFF_HI = $D416
SID_FILTER_RES       = $D417
SID_FILTER_MODE      = $D418
SID_VOLUME           = $D418
SID_POTX             = $D419
SID_POTY             = $D41A
SID_OSC3             = $D41B
SID_ENV3             = $D41C

; ============================================================================
; CIA1 Registers ($DC00 - $DC0F)
; ============================================================================
CIA1_PRA      = $DC00
CIA1_PRB      = $DC01
CIA1_DDRA     = $DC02
CIA1_DDRB     = $DC03
CIA1_TA_LO    = $DC04
CIA1_TA_HI    = $DC05
CIA1_TB_LO    = $DC06
CIA1_TB_HI    = $DC07
CIA1_TOD_10TH = $DC08
CIA1_TOD_SEC  = $DC09
CIA1_TOD_MIN  = $DC0A
CIA1_TOD_HR   = $DC0B
CIA1_SDR      = $DC0C
CIA1_ICR      = $DC0D
CIA1_CRA      = $DC0E
CIA1_CRB      = $DC0F

; ============================================================================
; CIA2 Registers ($DD00 - $DD0F)
; ============================================================================
CIA2_PRA      = $DD00
CIA2_PRB      = $DD01
CIA2_DDRA     = $DD02
CIA2_DDRB     = $DD03
CIA2_TA_LO    = $DD04
CIA2_TA_HI    = $DD05
CIA2_TB_LO    = $DD06
CIA2_TB_HI    = $DD07
CIA2_TOD_10TH = $DD08
CIA2_TOD_SEC  = $DD09
CIA2_TOD_MIN  = $DD0A
CIA2_TOD_HR   = $DD0B
CIA2_SDR      = $DD0C
CIA2_ICR      = $DD0D
CIA2_CRA      = $DD0E
CIA2_CRB      = $DD0F

; ============================================================================
; CPU Registers and Vectors
; ============================================================================
CPU_PORT      = $01
CPU_DDR       = $00
CPU_VEC_NMI   = $FFFA
CPU_VEC_RESET = $FFFC
CPU_VEC_IRQ   = $FFFE

; ============================================================================
; Utility Macros
; ============================================================================

; Macro: SAFE_SEI
; Purpose: Push processor status register and disable interrupts safely
; Clobber: None
#define SAFE_SEI php : sei

; Macro: SAFE_CLI
; Purpose: Restore processor status register from stack (enabling interrupts if they were enabled)
; Clobber: None
#define SAFE_CLI plp

; Macro: SET_VIC_BANK
; Purpose: Switch the VIC-II memory bank (0-3)
; Inputs: bank (constant bank index 0, 1, 2, or 3)
; Clobber: A
#define SET_VIC_BANK(bank) lda $DD00 : and #$FC : ora #(3-(bank)) : sta $DD00
