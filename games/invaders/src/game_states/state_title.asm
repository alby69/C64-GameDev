; ============================================================================
; MODULE: state_title.asm
; PURPOSE: Title Screen State Handler
; ============================================================================

state_title_enter:
        ; Clear screen
        lda #$20                ; Space character
        ldy #$01                ; White color
        jsr vic_clear_screen

        ; Draw Title Text
        ldx #0
_draw_title_loop:
        lda mTitleText,x
        beq _draw_title_done
        sta SCREEN_MEM + 120,x  ; Approx middle of screen
        lda #$01                ; White color
        sta COLOR_MEM + 120,x
        inx
        jmp _draw_title_loop

_draw_title_done:
        ; Draw Subtitle / Instructions
        ldx #0
_draw_sub_loop:
        lda mSubtitleText,x
        beq _draw_sub_done
        sta SCREEN_MEM + 320,x
        lda #$05                ; Green color
        sta COLOR_MEM + 320,x
        inx
        jmp _draw_sub_loop

_draw_sub_done:
        rts

state_title_exit:
        rts

state_title_update:
        ; Check if player wants to start the game
        lda #ACTION_FIRE
        jsr input_map_action
        cmp #1
        bne _title_no_start

        ; Play selection sound effect
        lda #GAME_SFX_SHOOT
        jsr sid_play_effect

        ; Transition to Play state
        lda #STATE_PLAY
        jsr state_change

_title_no_start:
        rts

state_title_draw:
        rts

mTitleText:
        ; "SPACE INVADERS" in screen codes (where A=1, B=2, ..., SPACE=32, etc.)
        .byte 19, 16, 1, 3, 5, 32, 9, 14, 22, 1, 4, 5, 18, 19, 0  ; "SPACE INVADERS"

mSubtitleText:
        ; "PRESS FIRE TO START"
        .byte 16, 18, 5, 19, 19, 32, 6, 9, 18, 5, 32, 20, 15, 32, 19, 20, 1, 18, 20, 0
