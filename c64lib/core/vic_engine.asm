; ============================================================================
; MODULE: vic_engine.asm
; PURPOSE: Video init, charset copy, screen clear, and VIC-II helpers
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Zero page temporary pointers
ZFB = $FB
ZFC = $FC

; ----------------------------------------------------------------------------
; ROUTINE: vic_init
; PURPOSE: Initialize VIC-II with screen bank, charset bank, and default colors
; INPUT: A = screen bank (0-15), X = charset bank (0-7), Y = colors (border/bg)
; ----------------------------------------------------------------------------
vic_init:
        ; Compute VIC_MEM register value: (screen_bank << 4) | (charset_bank << 1)
        PHA
        TXA
        ASL                     ; Shift charset bank left by 1
        STA _vic_mem_temp
        PLA
        ASL
        ASL
        ASL
        ASL                     ; Shift screen bank left by 4
        ORA _vic_mem_temp
        STA VIC_MEM             ; Configure VIC-II memory layout

        ; Set colors
        TYA
        AND #$0F                ; Border color in lower nibble
        STA VIC_BORDER
        TYA
        LSR
        LSR
        LSR
        LSR                     ; BG color in upper nibble (or keep simple)
        STA VIC_BG
        RTS

_vic_mem_temp:
        .byte $00

; ----------------------------------------------------------------------------
; ROUTINE: vic_set_bank
; PURPOSE: Set the 16KB VIC bank
; INPUT: A = bank (0-3)
; ----------------------------------------------------------------------------
vic_set_bank:
        EOR #$03                ; 3 - bank
        PHA
        LDA CIA2_PRA
        AND #$FC
        STA _vic_bank_temp
        PLA
        ORA _vic_bank_temp
        STA CIA2_PRA
        RTS

_vic_bank_temp:
        .byte $00

; ----------------------------------------------------------------------------
; ROUTINE: vic_copy_charset
; PURPOSE: Copy 2KB custom charset
; INPUT: ZFB = src pointer, ZFC = dst pointer (Zero page addresses)
; ----------------------------------------------------------------------------
vic_copy_charset:
        LDY #0
        LDX #8                  ; 8 pages of 256 bytes = 2KB
_vic_copy_loop:
        LDA (ZFB),Y
        STA (ZFC),Y
        INY
        BNE _vic_copy_loop
        INC ZFB+1
        INC ZFC+1
        DEX
        BNE _vic_copy_loop
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: vic_clear_screen
; PURPOSE: Clear Screen RAM and Color RAM
; INPUT: A = fill character, Y = fill color
; ----------------------------------------------------------------------------
vic_clear_screen:
        LDX #0
_vic_clear_loop:
        STA SCREEN_MEM,X
        STA SCREEN_MEM+$100,X
        STA SCREEN_MEM+$200,X
        STA SCREEN_MEM+$300,X

        PHA
        TYA
        STA COLOR_MEM,X
        STA COLOR_MEM+$100,X
        STA COLOR_MEM+$200,X
        STA COLOR_MEM+$300,X
        PLA

        INX
        BNE _vic_clear_loop
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: vic_wait_raster
; PURPOSE: Wait for specific raster line
; INPUT: A = raster line
; ----------------------------------------------------------------------------
vic_wait_raster:
_vic_wait_raster_loop:
        CMP VIC_RASTER
        BNE _vic_wait_raster_loop
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: vic_set_colors
; PURPOSE: Set border and background colors
; INPUT: A = border color, X = background color
; ----------------------------------------------------------------------------
vic_set_colors:
        STA VIC_BORDER
        STX VIC_BG
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: vic_enable_sprites
; PURPOSE: Enable/disable sprites
; INPUT: A = sprite mask
; ----------------------------------------------------------------------------
vic_enable_sprites:
        STA VIC_SPR_EN
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: vic_set_sprite_pos
; PURPOSE: Set sprite position (8-bit)
; INPUT: X = sprite ID (0-7), Y = X coordinate, A = Y coordinate
; ----------------------------------------------------------------------------
vic_set_sprite_pos:
        PHA                     ; Save Y coordinate
        TXA
        ASL                     ; sprite_id * 2
        TAX
        TYA                     ; X coordinate
        STA VIC_SPR0_X,X
        PLA                     ; Restore Y coordinate
        STA VIC_SPR0_X+1,X
        RTS
