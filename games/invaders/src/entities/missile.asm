; ============================================================================
; MODULE: missile.asm
; PURPOSE: Missile/Bullet entity logic
; ============================================================================

missile_init:
        lda #0
        sta mActiveMissiles
        rts

mActiveMissiles: .byte $00
