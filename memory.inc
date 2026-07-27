; ****************************************************************************
; memory.inc -- Centralized memory map, constants and register definitions
; ****************************************************************************
; Purpose: centralize definitions for all zero-page variables, registers,
; page 2 & 3 state variables, and game constants.
; ****************************************************************************

; ============================================================================
; KERNAL C64
; ============================================================================
BSOUT      = $FFD2
GET        = $FFE4
KERNAL_IRQ = $EA31     ; Standard Kernal IRQ entry

; ============================================================================
; HARDWARE C64 Registers
; ============================================================================
CIA1_PRA   = $DC00
CIA1_PRB   = $DC01
CIA1_DDRA  = $DC02
CIA1_DDRB  = $DC03

SID_FREQ_LO1 = $D400
SID_FREQ_HI1 = $D401
SID_CTRL1    = $D404
SID_ATT_DEC1 = $D405
SID_SUST_REL1= $D406
SID_VOL      = $D418
SID_RANDOM   = $D41B

VIC_MEM     = $D018
VIC_BORDER  = $D020
VIC_BG      = $D021
VIC_RASTER  = $D012

IRQ_VEC     = $0314
NMI_VEC     = $0318

; ============================================================================
; SCREEN CONSTANTS
; ============================================================================
SCREEN_WIDTH  = 40
SCREEN_HEIGHT = 25
SCREEN_MEM    = $0400
COLOR_MEM     = $D800

; ============================================================================
; ZERO PAGE VARIABLES
; ============================================================================
Z0A = $0A
Z0B = $0B
Z50 = $50
Z51 = $51
Z52 = $52
Z53 = $53
Z6E = $6E
Z6F = $6F
Z8F = $8F
ZCB = $CB
ZB3 = $B3
ZD6 = $D6
ZD7 = $D7
ZFB = $FB
ZFC = $FC

; ============================================================================
; VARIABILI PAGINA 2
; ============================================================================
M0280 = $0280
M0281 = $0281
M0282 = $0282
M0283 = $0283
M0284 = $0284
M0285 = $0285
M0286 = $0286
M0287 = $0287
M0288 = $0288
M0289 = $0289

; New custom game variables allocated in free page 2 space
SYSTEM_TYPE          = $028A  ; 0 = PAL, 1 = NTSC
FIRE_DEBOUNCE_TIMER  = $028B  ; Debounce counter for fire button
SYNC_LINE_VAL        = $028C  ; Target raster line for sync

M0292 = $0292
M0293 = $0293
M0294 = $0294
M02A0 = $02A0
M02A1 = $02A1
M02A2 = $02A2
M02A3 = $02A3
M02A4 = $02A4

; ============================================================================
; VARIABILI PAGINA 3
; ============================================================================
M033C = $033C
M033D = $033D
M033E = $033E
M033F = $033F
M0340 = $0340
M03C0 = $03C0
M03C1 = $03C1
M03C4 = $03C4
M03C5 = $03C5
M03C6 = $03C6
M03C7 = $03C7
M03C8 = $03C8
M03C9 = $03C9
M03CA = $03CA
M03CB = $03CB
M03CC = $03CC
M03CD = $03CD
M03CE = $03CE
M03D0 = $03D0
M03D1 = $03D1
M03D2 = $03D2
M03D4 = $03D4
M03D5 = $03D5
M03D6 = $03D6
M03D7 = $03D7
M03D8 = $03D8
M03D9 = $03D9
M03DA = $03DA
M03DB = $03DB
M03DC = $03DC
M03DD = $03DD
M03DE = $03DE
M03E0 = $03E0
M03E1 = $03E1
M03E2 = $03E2
M03E3 = $03E3
M03E4 = $03E4
M03E5 = $03E5
M03E6 = $03E6
M03E7 = $03E7
M03F0 = $03F0
M03F1 = $03F1
M03F2 = $03F2
M03F3 = $03F3
M03F4 = $03F4
M03F5 = $03F5
M03F8 = $03F8
