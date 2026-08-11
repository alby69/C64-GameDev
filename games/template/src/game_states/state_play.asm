; ============================================================================
; MODULE: state_play.asm
; PURPOSE: Template Play Screen State Handler
; ============================================================================

state_play_enter:
        ; Clear screen
        lda #$20
        ldy #$01
        jsr vic_clear_screen

        ; Set initial player position
        lda #18
        sta PLAYER_SPRITE_DEF + SPRITE_X
        lda #22
        sta PLAYER_SPRITE_DEF + SPRITE_Y

        ; Draw initial player
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_draw
        rts

state_play_exit:
        rts

state_play_update:
        ; Check for pause
        lda #ACTION_PAUSE
        jsr input_map_action
        cmp #1
        bne _play_no_pause
        lda #STATE_PAUSE
        jsr state_change
        rts

_play_no_pause:
        ; Clear old player sprite
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_clear

        ; Read input and update player position
        lda #ACTION_LEFT
        jsr input_map_action
        cmp #1
        bne _play_check_right
        dec PLAYER_SPRITE_DEF + SPRITE_X
        jmp _play_clipped

_play_check_right:
        lda #ACTION_RIGHT
        jsr input_map_action
        cmp #1
        bne _play_clipped
        inc PLAYER_SPRITE_DEF + SPRITE_X

_play_clipped:
        ; Clip player position
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_clip
        rts

state_play_draw:
        ; Draw player
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_draw
        rts
