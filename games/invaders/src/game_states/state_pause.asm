; ============================================================================
; MODULE: state_pause.asm
; PURPOSE: Pause Overlay State Handler
; ============================================================================

state_pause_enter:
        ; Draw "PAUSED" message overlay
        ldx #0
_pause_draw_loop:
        lda mPausedText,x
        beq _pause_draw_done
        sta SCREEN_MEM + 497,x  ; Near screen center
        lda #$07                ; Yellow color
        sta COLOR_MEM + 497,x
        inx
        jmp _pause_draw_loop

_pause_draw_done:
        rts

state_pause_exit:
        ; Clean up/erase "PAUSED" text by overwriting with space
        ldx #0
        lda #$20                ; Space character
_pause_clear_loop:
        cpx #6
        beq _pause_clear_done
        sta SCREEN_MEM + 497,x
        inx
        jmp _pause_clear_loop
_pause_clear_done:
        rts

state_pause_update:
        ; Check pause button to resume play
        lda #ACTION_PAUSE
        jsr input_map_action
        cmp #1
        bne _pause_no_resume

        ; Resume play state
        lda #STATE_PLAY
        jsr state_change

_pause_no_resume:
        rts

state_pause_draw:
        rts

mPausedText:
        .byte 16, 1, 21, 19, 5, 4, 0    ; "PAUSED"
