; ============================================================================
; MODULE: sprite_data.asm
; PURPOSE: Raw Sprite frames and structures for Space Invaders character sprites
; ============================================================================

; Width and Height of the player/invader sprites in characters (e.g. 5 wide, 3 high)
SPR_CHAR_WIDTH  = 5
SPR_CHAR_HEIGHT = 3

; Player Sprite Definition
PLAYER_SPRITE_DEF:
        .byte 18, 22            ; X, Y starting coordinates
        .byte 5, 1              ; Width (5 chars), Height (1 char)
        .byte 0                 ; Active Frame
        .byte $80 | $05         ; Active (Bit 7), Char Sprite (Bit 6=0), Green Color (5)
        .word mPlayerSpriteData

mPlayerSpriteData:
        .byte $58, $2C, $59, $29, $00  ; Standard green player cannon shape

; Invader Type A Definition
INVADER_A_SPRITE_DEF:
        .byte 0, 0              ; X, Y coordinates (dynamic)
        .byte 5, 3              ; Width (5 chars), Height (3 chars)
        .byte 0                 ; Active Frame
        .byte $80 | $01         ; Active, White Color (1)
        .word mInvaderAData

mInvaderAData:
        ; Frame 0 (5x3 chars)
        .byte $FF, $E3, $7F, $20, $20
        .byte $FC, $99, $FE, $20, $20
        .byte $E9, $F2, $DF, $20, $20
        ; Frame 1
        .byte $FF, $E3, $7F, $20, $20
        .byte $62, $99, $62, $20, $20
        .byte $E9, $F2, $DF, $20, $20
