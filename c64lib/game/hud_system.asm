; ============================================================================
; MODULE: hud_system.asm
; PURPOSE: HUD Render and BCD Score tracking system for C64 games
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y, SR
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Screen character definitions (Screen Codes)
CHAR_S = $13
CHAR_C = $03
CHAR_O = $0F
CHAR_R = $12
CHAR_E = $05
CHAR_P = $10
CHAR_1 = $31
CHAR_2 = $32
CHAR_H = $08
CHAR_I = $09
CHAR_L = $0C
CHAR_V = $16
CHAR_COLON = $3A
CHAR_SPACE = $20

; Zero Page workspace
; Using standard $FB-$FD area
zHudDest      = $FB
zHudColorDest = $FD

; ----------------------------------------------------------------------------
; ROUTINE: hud_init
; PURPOSE: Initialize HUD position and text color
; INPUT: A = position (0 = top, 1 = bottom), X = text color
; ----------------------------------------------------------------------------
hud_init:
        STA mHudPosition
        STX mHudColor

        ; Initialize defaults
        LDA #3                  ; 3 lives
        STA mHudLives
        LDA #$6C                ; heart icon
        STA mHudLivesIcon

        LDA #0
        STA mP1Score
        STA mP1Score+1
        STA mP1Score+2
        STA mP2Score
        STA mP2Score+1
        STA mP2Score+2
        STA mHighScore
        STA mHighScore+1
        STA mHighScore+2
        STA mHudTimer
        STA mFlashActive
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: hud_set_score
; PURPOSE: Set score bytes (6-digit BCD: 3 bytes)
; INPUT: A = player (0 = P1, 1 = P2)
;        $FB = low byte, $FC = mid byte, $FD = high byte
; ----------------------------------------------------------------------------
hud_set_score:
        CMP #0
        BNE _hss_p2
        LDA $FB
        STA mP1Score
        LDA $FC
        STA mP1Score+1
        LDA $FD
        STA mP1Score+2
        RTS
_hss_p2:
        LDA $FB
        STA mP2Score
        LDA $FC
        STA mP2Score+1
        LDA $FD
        STA mP2Score+2
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: hud_set_lives
; PURPOSE: Set lives count and icon
; INPUT: A = lives count, X = lives icon screen code
; ----------------------------------------------------------------------------
hud_set_lives:
        STA mHudLives
        STX mHudLivesIcon
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: hud_set_high_score
; PURPOSE: Set high score bytes (6-digit BCD)
; INPUT: $FB = low byte, $FC = mid byte, $FD = high byte
; ----------------------------------------------------------------------------
hud_set_high_score:
        LDA $FB
        STA mHighScore
        LDA $FC
        STA mHighScore+1
        LDA $FD
        STA mHighScore+2
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: hud_set_timer
; PURPOSE: Set timer in seconds
; INPUT: A = seconds
; ----------------------------------------------------------------------------
hud_set_timer:
        STA mHudTimer
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: hud_flash
; PURPOSE: Flash HUD element
; INPUT: A = element_id (0 = P1, 1 = High Score, 2 = Lives)
;        X = duration (frames)
;        Y = flash color
; ----------------------------------------------------------------------------
hud_flash:
        STA mFlashActive
        STX mFlashDuration
        STY mFlashColor
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: hud_draw
; PURPOSE: Draw HUD onto Screen RAM and Color RAM
; ----------------------------------------------------------------------------
hud_draw:
        ; 1. Calculate base addresses based on position (top or bottom)
        LDA mHudPosition
        BEQ _hd_top

        ; Bottom (line 24, address $0400 + 960 = $07C0)
        LDA #<$07C0
        STA mHudBaseL
        LDA #>$07C0
        STA mHudBaseH
        JMP _hd_draw_row

_hd_top:
        ; Top (line 0, address $0400)
        LDA #<$0400
        STA mHudBaseL
        LDA #>$0400
        STA mHudBaseH

_hd_draw_row:
        ; Set zero page pointers
        LDA mHudBaseL
        STA zHudDest
        LDA mHudBaseH
        STA zHudDest+1

        ; Calculate Color RAM matching offset
        LDA zHudDest
        STA zHudColorDest
        LDA zHudDest+1
        AND #$03
        ORA #$D8
        STA zHudColorDest+1

        ; 2. Render Text buffer row
        ; Layout (40 chars):
        ; "P1:XXXXXX   HI:XXXXXX   LIVES:♥♥♥"
        ; 0123456789012345678901234567890123456789

        ; Clear row first with spaces
        LDY #39
        LDA #CHAR_SPACE
_hd_clear_row:
        STA (zHudDest),Y
        DEY
        BPL _hd_clear_row

        ; Draw P1 label: "P1:"
        LDY #0
        LDA #CHAR_P
        STA (zHudDest),Y
        INY
        LDA #CHAR_1
        STA (zHudDest),Y
        INY
        LDA #CHAR_COLON
        STA (zHudDest),Y

        ; Unpack and draw P1 BCD score (6 digits)
        ; Digits start at Y = 3
        LDA mP1Score+2          ; High BCD byte
        JSR _hud_unpack_byte
        STA mUnpackTemp
        TXA
        LDY #3
        STA (zHudDest),Y
        LDA mUnpackTemp
        INY
        STA (zHudDest),Y

        LDA mP1Score+1          ; Mid BCD byte
        JSR _hud_unpack_byte
        STA mUnpackTemp
        TXA
        LDY #5
        STA (zHudDest),Y
        LDA mUnpackTemp
        INY
        STA (zHudDest),Y

        LDA mP1Score            ; Low BCD byte
        JSR _hud_unpack_byte
        STA mUnpackTemp
        TXA
        LDY #7
        STA (zHudDest),Y
        LDA mUnpackTemp
        INY
        STA (zHudDest),Y

        ; Draw HI label: "HI:" at col 12
        LDY #12
        LDA #CHAR_H
        STA (zHudDest),Y
        INY
        LDA #CHAR_I
        STA (zHudDest),Y
        INY
        LDA #CHAR_COLON
        STA (zHudDest),Y

        ; High Score BCD (6 digits) at col 15
        LDA mHighScore+2
        JSR _hud_unpack_byte
        STA mUnpackTemp
        TXA
        LDY #15
        STA (zHudDest),Y
        LDA mUnpackTemp
        INY
        STA (zHudDest),Y

        LDA mHighScore+1
        JSR _hud_unpack_byte
        STA mUnpackTemp
        TXA
        LDY #17
        STA (zHudDest),Y
        LDA mUnpackTemp
        INY
        STA (zHudDest),Y

        LDA mHighScore
        JSR _hud_unpack_byte
        STA mUnpackTemp
        TXA
        LDY #19
        STA (zHudDest),Y
        LDA mUnpackTemp
        INY
        STA (zHudDest),Y

        ; Draw LIVES label: "LIVES:" at col 26
        LDY #26
        LDA #CHAR_L
        STA (zHudDest),Y
        INY
        LDA #CHAR_I
        STA (zHudDest),Y
        INY
        LDA #CHAR_V
        STA (zHudDest),Y
        INY
        LDA #CHAR_E
        STA (zHudDest),Y
        INY
        LDA #CHAR_S
        STA (zHudDest),Y
        INY
        LDA #CHAR_COLON
        STA (zHudDest),Y

        ; Draw Lives icons at col 32 (up to 5 icons)
        LDA mHudLives
        BEQ _hd_draw_colors     ; No lives left
        CMP #6
        BCC _hd_lives_ok
        LDA #5                  ; Cap display to 5 max
_hd_lives_ok:
        TAX                     ; X = count
        LDY #32                 ; Start column
_hd_lives_loop:
        LDA mHudLivesIcon
        STA (zHudDest),Y
        INY
        DEX
        BNE _hd_lives_loop

_hd_draw_colors:
        ; 3. Write Color RAM
        ; Check if flash is active and decrement flash counter
        LDA mFlashActive
        BEQ _hd_draw_colors_normal

        ; Decrement timer
        DEC mFlashDuration
        BNE _hd_colors_flash
        LDA #0                  ; Flash ended
        STA mFlashActive

_hd_colors_flash:
        ; Draw flash color
        LDY #39
_hd_col_flash_loop:
        LDA mFlashColor
        STA (zHudColorDest),Y
        DEY
        BPL _hd_col_flash_loop
        RTS

_hd_draw_colors_normal:
        ; Use normal HUD color
        LDY #39
_hd_col_norm_loop:
        LDA mHudColor
        STA (zHudColorDest),Y
        DEY
        BPL _hd_col_norm_loop
        RTS

; ----------------------------------------------------------------------------
; HELPER: _hud_unpack_byte
; PURPOSE: Unpack 1 BCD byte into 2 screen code digits
; INPUT: A = BCD byte (e.g. $56)
; OUTPUT: X = first digit screen code ($35), A = second digit screen code ($36)
; ----------------------------------------------------------------------------
_hud_unpack_byte:
        PHA
        AND #$0F
        CLC
        ADC #$30                ; Convert to number screen code
        STA mUnpackTemp2
        PLA
        LSR
        LSR
        LSR
        LSR                     ; Shift top nibble down
        CLC
        ADC #$30
        TAX                     ; X = first digit
        LDA mUnpackTemp2        ; A = second digit
        RTS

; ----------------------------------------------------------------------------
; STORAGE VARIABLES
; ----------------------------------------------------------------------------
mHudPosition:      .byte $00    ; 0 = top, 1 = bottom
mHudColor:         .byte $01    ; White default
mHudLives:         .byte $03
mHudLivesIcon:     .byte $6C    ; Default icon
mHudTimer:         .byte $00

mHudBaseL:         .byte $00
mHudBaseH:         .byte $00

mP1Score:          .dsb 3, 0    ; 3 BCD bytes (6 digits)
mP2Score:          .dsb 3, 0
mHighScore:        .dsb 3, 0

mFlashActive:      .byte $00
mFlashDuration:    .byte $00
mFlashColor:       .byte $00

mUnpackTemp:       .byte $00
mUnpackTemp2:      .byte $00
