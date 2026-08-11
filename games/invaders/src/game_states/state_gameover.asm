; ============================================================================
; MODULE: state_gameover.asm
; PURPOSE: Game Over State Handler
; ============================================================================

state_gameover_enter:
        ; Play GameOver sound
        lda #GAME_SFX_GAMEOVER
        jsr sid_play_effect

        ; Clear screen
        lda #$20
        ldy #$02                ; Red border / black background
        jsr vic_clear_screen

        ; Draw GAME OVER Text
        ldx #0
_gameover_lbl_loop:
        lda mGameOverText,x
        beq _gameover_lbl_done
        sta SCREEN_MEM + 246,x
        lda #$02                ; Red color
        sta COLOR_MEM + 246,x
        inx
        jmp _gameover_lbl_loop

_gameover_lbl_done:
        ; Draw restart instructions
        ldx #0
_gameover_inst_loop:
        lda mRestartText,x
        beq _gameover_inst_done
        sta SCREEN_MEM + 488,x
        lda #$01                ; White color
        sta COLOR_MEM + 488,x
        inx
        jmp _gameover_inst_loop

_gameover_inst_done:
        rts

state_gameover_exit:
        rts

state_gameover_update:
        ; Check if player wants to restart or return to title screen
        lda #ACTION_RESTART
        jsr input_map_action
        cmp #1
        beq _gameover_restart

        lda #ACTION_FIRE
        jsr input_map_action
        cmp #1
        bne _gameover_done

_gameover_restart:
        ; Go back to Title Screen
        lda #STATE_TITLE
        jsr state_change

_gameover_done:
        rts

state_gameover_draw:
        rts

mGameOverText:
        .byte 7, 1, 13, 5, 32, 15, 22, 5, 18, 0  ; "GAME OVER"

mRestartText:
        .byte 16, 18, 5, 19, 19, 32, 6, 1, 3, 20, 15, 18, 20, 32, 20, 15, 32, 18, 5, 19, 20, 1, 18, 20, 0  ; "PRESS F1 OR FIRE TO RESTART"
