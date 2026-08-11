; ============================================================================
; MODULE: player.asm
; PURPOSE: Player character entity initialization and helper routines
; ============================================================================

player_init:
        lda #18
        sta PLAYER_SPRITE_DEF + SPRITE_X
        lda #22
        sta PLAYER_SPRITE_DEF + SPRITE_Y
        rts
