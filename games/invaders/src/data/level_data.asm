; ============================================================================
; MODULE: level_data.asm
; PURPOSE: Generalized level structures and settings for Space Invaders
; ============================================================================

LEVEL_STRUCT_SIZE = 16

LEVEL_STRUCT:
        .byte $00       ; num_invaders
        .byte $00       ; num_rows
        .byte $00       ; num_cols
        .dsb 5, 0       ; invader_types
        .byte $00       ; initial_speed
        .byte $00       ; speed_increment
        .word $0000     ; bonus_frequency
        .byte $00       ; bunker_count
        .word $0000     ; score_per_invader
        .word $0000     ; palette_ptr

LEVEL_1:
        .byte 55, 5, 11
        .byte $03, $03, $03, $02, $02
        .byte 8, 1
        .word 256
        .byte 4
        .word SCORE_TABLE_STD
        .word PALETTE_CLASSIC

LEVEL_2:
        .byte 55, 5, 11
        .byte $03, $03, $02, $02, $01
        .byte 6, 1
        .word 200
        .byte 3
        .word SCORE_TABLE_HARD
        .word PALETTE_GREEN

SCORE_TABLE_STD:
        .word $0010, $0020, $0030

SCORE_TABLE_HARD:
        .word $0020, $0040, $0060

PALETTE_CLASSIC:
        .byte $05, $05, $05, $05, $05   ; all green

PALETTE_GREEN:
        .byte $05, $05, $05, $05, $05   ; green
