; ============================================================================
; MODULE: invader.asm
; PURPOSE: Invader entity movement and state logic
; DEPENDS: c64lib/hal/c64_hardware.inc
; ============================================================================

; SMC removed for ROM compatibility (Variables are allocated in RAM instead of inline SMC)
mInvaderSpeedDelay: .byte $08
mMaxMissiles:       .byte $06

invader_init:
        lda #$08
        sta mInvaderSpeedDelay  ; Store default speed delay in RAM variable
        lda #$06
        sta mMaxMissiles        ; Store max active missiles limit in RAM variable
        rts

invader_update_speed:
        ; Input: A = new speed delay
        sta mInvaderSpeedDelay  ; No self-modification needed
        rts

invader_get_max_missiles:
        lda mMaxMissiles
        rts
