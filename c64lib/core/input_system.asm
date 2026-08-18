; ============================================================================
; MODULE: input_system.asm
; PURPOSE: Keyboard matrix scanning and joystick helpers
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Action IDs
ACTION_FIRE     = 0
ACTION_LEFT     = 1
ACTION_RIGHT    = 2
ACTION_PAUSE    = 3
ACTION_RESTART  = 4

; ----------------------------------------------------------------------------
; ROUTINE: input_init
; PURPOSE: Configure CIA1 for keyboard scanning and joystick input
; ----------------------------------------------------------------------------
input_init:
        LDA #$FF
        STA CIA1_DDRA   ; Port A to output (for keyboard column select)
        LDA #$00
        STA CIA1_DDRB   ; Port B to input (for keyboard rows / joystick 2)
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: input_scan_joystick
; PURPOSE: Read joystick state for Port 1 or 2
; INPUT: A = port (1 or 2)
; OUTPUT: A = joystick bits (Bit 0=Up, 1=Down, 2=Left, 3=Right, 4=Fire) [1=pressed]
; ----------------------------------------------------------------------------
input_scan_joystick:
        CMP #1
        BEQ _scan_port1
        ; Read Port 2 (CIA1_PRB)
        LDA CIA1_PRB
        EOR #$FF
        AND #$1F
        RTS
_scan_port1:
        ; Read Port 1 (CIA1_PRA)
        LDA CIA1_PRA
        EOR #$FF
        AND #$1F
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: input_scan_keyboard
; PURPOSE: Read the active keyboard matrix code
; OUTPUT: A = matrix code (0-63, 64 if none), X = row index, Y = column index
; ----------------------------------------------------------------------------
input_scan_keyboard:
        LDA $CB                 ; Kernal active matrix code
        PHA
        ; Derive Row and Column indexes if key is pressed (for completeness)
        CMP #64
        BEQ _scan_kb_none
        AND #$07
        TAX                     ; Row = bits 0-2
        PLA
        LSR
        LSR
        LSR
        AND #$07
        TAY                     ; Col = bits 3-5
        TXA                     ; Restore matrix code in A
        RTS
_scan_kb_none:
        PLA
        LDX #$00
        LDY #$00
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: input_get_key
; PURPOSE: Translate current matrix code to PETSCII
; OUTPUT: A = PETSCII char or 0 if none
; ----------------------------------------------------------------------------
input_get_key:
        LDA $CB
        CMP #64
        BEQ _get_key_none
        CMP #10
        BEQ _get_key_a
        CMP #18
        BEQ _get_key_d
        CMP #29
        BEQ _get_key_j
        CMP #60
        BEQ _get_key_space
        CMP #15
        BEQ _get_key_p
        CMP #4
        BEQ _get_key_f1
        LDA #0                  ; Unknown/unsupported key
        RTS
_get_key_none:
        LDA #0
        RTS
_get_key_a:
        LDA #$41
        RTS
_get_key_d:
        LDA #$44
        RTS
_get_key_j:
        LDA #$4A
        RTS
_get_key_space:
        LDA #$20
        RTS
_get_key_p:
        LDA #$50
        RTS
_get_key_f1:
        LDA #$85
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: input_map_action
; PURPOSE: Check if mapped key or joystick input is active for action
; INPUT: A = action ID (ACTION_FIRE, etc.)
; OUTPUT: A = 1 if active, 0 if inactive
; ----------------------------------------------------------------------------
input_map_action:
        CMP #ACTION_FIRE
        BEQ _action_fire_check
        CMP #ACTION_LEFT
        BEQ _action_left_check
        CMP #ACTION_RIGHT
        BEQ _action_right_check
        CMP #ACTION_PAUSE
        BEQ _action_pause_check
        CMP #ACTION_RESTART
        BEQ _action_restart_check
        LDA #0
        RTS

_action_fire_check:
        LDA $CB
        CMP #60                 ; Space
        BEQ _action_active
        CMP #29                 ; 'J'
        BEQ _action_active
        LDA CIA1_PRB
        AND #$10                ; Joy 2 Fire (active-low)
        BEQ _action_active
        JMP _action_inactive

_action_left_check:
        LDA $CB
        CMP #10                 ; 'A'
        BEQ _action_active
        LDA CIA1_PRB
        AND #$04                ; Joy 2 Left (active-low)
        BEQ _action_active
        JMP _action_inactive

_action_right_check:
        LDA $CB
        CMP #18                 ; 'D'
        BEQ _action_active
        LDA CIA1_PRB
        AND #$08                ; Joy 2 Right (active-low)
        BEQ _action_active
        JMP _action_inactive

_action_pause_check:
        LDA $CB
        CMP #15                 ; 'P'
        BEQ _action_active
        JMP _action_inactive

_action_restart_check:
        LDA $CB
        CMP #4                  ; F1
        BEQ _action_active
        JMP _action_inactive

_action_active:
        LDA #1
        RTS
_action_inactive:
        LDA #0
        RTS

; ----------------------------------------------------------------------------
; STRUCTURED INPUT STATE
; ----------------------------------------------------------------------------
INPUT_STATE:
mJoy1State:      .byte $00
mJoy2State:      .byte $00
mKbMatrixCode:   .byte $00
mDebounceCount:  .byte $00
mActionFlags:    .byte $00
