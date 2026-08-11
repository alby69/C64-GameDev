; ============================================================================
; MODULE: state_play.asm
; PURPOSE: Play State Handler
; ============================================================================

state_play_enter:
        ; Reset scores and HUD
        lda #0
        sta mGameScore
        sta mGameScore+1
        lda #3
        sta mPlayerLives

        ; Clear screen
        lda #$20
        ldy #$05                ; Green border / black BG
        jsr vic_clear_screen

        ; Initialize HUD display
        jsr _draw_hud_labels

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
        ; Check for Pause transition
        lda #ACTION_PAUSE
        jsr input_map_action
        cmp #1
        bne _play_no_pause
        lda #STATE_PAUSE
        jsr state_change
        rts

_play_no_pause:
        ; 1. Clear player sprite first (from old position)
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_clear

        ; 2. Handle movement input
        lda #ACTION_LEFT
        jsr input_map_action
        cmp #1
        bne _play_check_right
        ; Move left: decrement X
        dec PLAYER_SPRITE_DEF + SPRITE_X
        jmp _play_clipped

_play_check_right:
        lda #ACTION_RIGHT
        jsr input_map_action
        cmp #1
        bne _play_clipped
        ; Move right: increment X
        inc PLAYER_SPRITE_DEF + SPRITE_X

_play_clipped:
        ; 3. Clip player within screen bounds
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_clip

        ; 4. Check for shooting input
        lda #ACTION_FIRE
        jsr input_map_action
        cmp #1
        bne _play_no_fire
        ; If fire, play sound effect
        lda #GAME_SFX_SHOOT
        jsr sid_play_effect
        ; Simulate score increment on shoot
        sed
        clc
        lda mGameScore
        adc #$10
        sta mGameScore
        lda mGameScore+1
        adc #$00
        sta mGameScore+1
        cld

_play_no_fire:
        ; 5. Update HUD score displays
        jsr _update_hud_score

        ; If player score is high enough, let's simulate game over for demonstration
        lda mGameScore+1
        cmp #$10
        bcc _play_done
        lda #STATE_GAMEOVER
        jsr state_change

_play_done:
        rts

state_play_draw:
        ; Draw player sprite at its current position
        lda #<PLAYER_SPRITE_DEF
        sta $FB
        lda #>PLAYER_SPRITE_DEF
        sta $FC
        jsr sprite_draw
        rts

_draw_hud_labels:
        ; Write "SCORE:" label to top-left of the screen
        ldx #0
_hud_lbl_loop:
        lda mScoreLabelText,x
        beq _hud_lbl_done
        sta SCREEN_MEM + 1,x
        lda #$01                ; White
        sta COLOR_MEM + 1,x
        inx
        jmp _hud_lbl_loop

_hud_lbl_done:
        rts

_update_hud_score:
        ; Unpack BCD score (mGameScore) and write to screen in decimal format
        ; High byte high nibble
        lda mGameScore+1
        lsr
        lsr
        lsr
        lsr
        ora #$30                ; Screen code mapping for digits '0'-'9'
        sta SCREEN_MEM + 8

        ; High byte low nibble
        lda mGameScore+1
        and #$0F
        ora #$30
        sta SCREEN_MEM + 9

        ; Low byte high nibble
        lda mGameScore
        lsr
        lsr
        lsr
        lsr
        ora #$30
        sta SCREEN_MEM + 10

        ; Low byte low nibble
        lda mGameScore
        and #$0F
        ora #$30
        sta SCREEN_MEM + 11

        rts

mScoreLabelText:
        .byte 19, 3, 15, 18, 5, 27, 0   ; "SCORE:"

mGameScore:        .byte $00, $00       ; BCD score tracking
mPlayerLives:      .byte $03
