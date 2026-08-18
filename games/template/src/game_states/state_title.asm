; ============================================================================
; MODULE: state_title.asm
; PURPOSE: Template Title Screen State Handler
; ============================================================================

state_title_enter:
        ; Clear screen
        lda #$20
        ldy #$01                ; White color
        jsr vic_clear_screen

        ; Draw Title Text
        ldx #0
_draw_title_loop:
        lda mTitleText,x
        beq _draw_title_done
        sta SCREEN_MEM + 120,x
        lda #$01
        sta COLOR_MEM + 120,x
        inx
        jmp _draw_title_loop

_draw_title_done:
        ; Draw Instruction
        ldx #0
_draw_sub_loop:
        lda mSubtitleText,x
        beq _draw_sub_done
        sta SCREEN_MEM + 320,x
        lda #$07                ; Yellow
        sta COLOR_MEM + 320,x
        inx
        jmp _draw_sub_loop

_draw_sub_done:
        rts

state_title_exit:
        rts

state_title_update:
        lda #ACTION_FIRE
        jsr input_map_action
        cmp #1
        bne _title_no_start

        lda #STATE_PLAY
        jsr state_change

_title_no_start:
        rts

state_title_draw:
        rts

mTitleText:
        .byte 20, 5, 13, 16, 12, 1, 20, 5, 32, 7, 1, 13, 5, 0  ; "TEMPLATE GAME"

mSubtitleText:
        .byte 16, 18, 5, 19, 19, 32, 6, 9, 18, 5, 32, 20, 15, 32, 19, 20, 1, 18, 20, 0 ; "PRESS FIRE TO START"
