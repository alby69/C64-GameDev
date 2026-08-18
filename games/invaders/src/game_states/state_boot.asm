; ============================================================================
; MODULE: state_boot.asm
; PURPOSE: Boot State Handler
; ============================================================================

STATE_TABLE:
        .word state_boot_enter,     state_boot_exit,     state_boot_update,     state_boot_draw
        .word state_title_enter,    state_title_exit,    state_title_update,    state_title_draw
        .word state_menu_enter,     state_menu_exit,     state_menu_update,     state_menu_draw
        .word state_play_enter,     state_play_exit,     state_play_update,     state_play_draw
        .word state_pause_enter,    state_pause_exit,    state_pause_update,    state_pause_draw
        .word state_gameover_enter, state_gameover_exit, state_gameover_update, state_gameover_draw
        .word state_high_enter,     state_high_exit,     state_high_update,     state_high_draw

state_boot_enter:
        ; Set standard PAL system sync line and border/bg colors (black/black)
        lda #15                 ; Border color: light gray
        ldx #0                  ; Charset bank: 0
        ldy #0                  ; Default black color
        jsr vic_init

        lda #0
        ldy #0
        jsr vic_clear_screen

        rts

state_boot_exit:
        rts

state_boot_update:
        ; Immediately transition to TITLE state
        lda #STATE_TITLE
        jsr state_change
        rts

state_boot_draw:
        rts

; Dummy High State for completeness of the 7-state table
state_high_enter:
        rts
state_high_exit:
        rts
state_high_update:
        rts
state_high_draw:
        rts
