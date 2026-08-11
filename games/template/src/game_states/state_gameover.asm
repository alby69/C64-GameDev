; ============================================================================
; MODULE: state_gameover.asm
; PURPOSE: Template Game Over State Handler
; ============================================================================

state_gameover_enter:
        lda #$20
        ldy #$02
        jsr vic_clear_screen

        ; Draw GAME OVER Text
        ldx #0
_gameover_lbl_loop:
        lda mGameOverText,x
        beq _gameover_lbl_done
        sta SCREEN_MEM + 246,x
        lda #$02
        sta COLOR_MEM + 246,x
        inx
        jmp _gameover_lbl_loop

_gameover_lbl_done:
        rts

state_gameover_exit:
        rts

state_gameover_update:
        lda #ACTION_FIRE
        jsr input_map_action
        cmp #1
        bne _gameover_done

        lda #STATE_TITLE
        jsr state_change

_gameover_done:
        rts

state_gameover_draw:
        rts

mGameOverText:
        .byte 7, 1, 13, 5, 32, 15, 22, 5, 18, 0  ; "GAME OVER"
