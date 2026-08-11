; ============================================================================
; MODULE: sid_engine.asm
; PURPOSE: SID sound engine for 3 channels and standard SFX playback
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Zero Page pointer for indirect indexed sound effects loading
mSidSfxPtr = $FB

; ----------------------------------------------------------------------------
; PRIVATE HELPERS & VARIABLES (Declared first to avoid forward-reference errors)
; ----------------------------------------------------------------------------
mSidTempLo:  .byte $00
mSidTempHi:  .byte $00
mSidTempWf:  .byte $00

; Structured Sound Effects Table
SFX_TABLE:
        .word sfx_shoot, sfx_explosion, sfx_step, sfx_bonus, sfx_gameover

sfx_shoot:
        .byte $00, $40          ; freq_lo, freq_hi (e.g. approx 4000Hz)
        .byte $11               ; waveform (triangle + gate)
        .byte $09, $00          ; AD, SR
        .byte 10                ; duration frames

sfx_explosion:
        .byte $00, $10
        .byte $81               ; waveform (noise + gate)
        .byte $0F, $40
        .byte 30

sfx_step:
        .byte $00, $05
        .byte $21               ; waveform (sawtooth + gate)
        .byte $02, $00
        .byte 5

sfx_bonus:
        .byte $00, $80
        .byte $11               ; waveform (triangle + gate)
        .byte $05, $F0
        .byte 20

sfx_gameover:
        .byte $00, $08
        .byte $21
        .byte $09, $90
        .byte 50

_sid_get_voice_offset:
        CMP #1
        BCC _v0
        BEQ _v1
        LDX #14
        RTS
_v0:    LDX #0
        RTS
_v1:    LDX #7
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_init
; PURPOSE: Reset all SID registers
; ----------------------------------------------------------------------------
sid_init:
        LDX #$1C
        LDA #$00
_sid_init_loop:
        STA $D400,X
        DEX
        BPL _sid_init_loop
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_play_note
; PURPOSE: Play a note/frequency on a channel
; INPUT: A = channel (0-2), X = freq_lo, Y = freq_hi
; ----------------------------------------------------------------------------
sid_play_note:
        STX mSidTempLo
        STY mSidTempHi
        JSR _sid_get_voice_offset
        LDA mSidTempLo
        STA SID_FREQ_LO1,X
        LDA mSidTempHi
        STA SID_FREQ_HI1,X
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_set_waveform
; PURPOSE: Set waveform and control bits for a channel
; INPUT: A = channel (0-2), X = waveform byte
; ----------------------------------------------------------------------------
sid_set_waveform:
        STX mSidTempWf
        JSR _sid_get_voice_offset
        LDA mSidTempWf
        STA SID_CTRL1,X
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_set_adsr
; PURPOSE: Set Attack/Decay and Sustain/Release for a channel
; INPUT: A = channel (0-2), X = attack|decay, Y = sustain|release
; ----------------------------------------------------------------------------
sid_set_adsr:
        STX mSidTempLo
        STY mSidTempHi
        JSR _sid_get_voice_offset
        LDA mSidTempLo
        STA SID_ATT_DEC1,X
        LDA mSidTempHi
        STA SID_SUST_REL1,X
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_stop_channel
; PURPOSE: Stop/release a channel by clearing control register
; INPUT: A = channel (0-2)
; ----------------------------------------------------------------------------
sid_stop_channel:
        JSR _sid_get_voice_offset
        LDA #$00
        STA SID_CTRL1,X
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_set_filter
; PURPOSE: Configure SID filter settings
; INPUT: A = filter mode/vol, X = cutoff_lo, Y = cutoff_hi
; ----------------------------------------------------------------------------
sid_set_filter:
        STA SID_FLT_CTRL
        STX SID_FLT_CUT_LO
        STY SID_FLT_CUT_HI
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_set_volume
; PURPOSE: Set master volume (0-15)
; INPUT: A = volume
; ----------------------------------------------------------------------------
sid_set_volume:
        AND #$0F
        STA SID_VOL
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sid_play_effect
; PURPOSE: Play pre-defined sound effect on Voice 1
; INPUT: A = effect_id (0-4)
; ----------------------------------------------------------------------------
sid_play_effect:
        ASL                     ; Multiply by 2 to get word index
        TAX
        LDA SFX_TABLE,X
        STA mSidSfxPtr
        LDA SFX_TABLE+1,X
        STA mSidSfxPtr+1

        LDY #0
        LDA (mSidSfxPtr),Y
        STA SID_FREQ_LO1
        INY
        LDA (mSidSfxPtr),Y
        STA SID_FREQ_HI1

        INY
        LDA (mSidSfxPtr),Y
        STA SID_CTRL1

        INY
        LDA (mSidSfxPtr),Y
        STA SID_ATT_DEC1
        INY
        LDA (mSidSfxPtr),Y
        STA SID_SUST_REL1
        RTS
