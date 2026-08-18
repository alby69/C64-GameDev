; ============================================================================
; MODULE: sprite_data.asm
; PURPOSE: Raw Sprite frames and structures for template game
; ============================================================================

PLAYER_SPRITE_DEF:
        .byte 18, 22            ; X, Y starting coordinates
        .byte 5, 1              ; Width (5 chars), Height (1 char)
        .byte 0                 ; Active Frame
        .byte $80 | $01         ; Active, White color (1)
        .word mPlayerSpriteData

mPlayerSpriteData:
        .byte $58, $2C, $59, $29, $00
