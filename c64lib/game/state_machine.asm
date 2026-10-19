; ============================================================================
; MODULE: state_machine.asm
; PURPOSE: Finite State Machine (FSM) for C64 game states
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y, SR
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; State definitions (Constants)
STATE_BOOT     = 0
STATE_TITLE    = 1
STATE_MENU     = 2
STATE_PLAY     = 3
STATE_PAUSE    = 4
STATE_GAMEOVER = 5
STATE_HIGH     = 6
STATE_NONE     = $FF

; Callback Offset Constants
STATE_CB_ENTER  = 0
STATE_CB_EXIT   = 2
STATE_CB_UPDATE = 4
STATE_CB_DRAW   = 6

; Zero Page workspace used for indirect addressing
zStateTempAddr = $FB   ; uses $FB and $FC

; ----------------------------------------------------------------------------
; ROUTINE: state_init
; PURPOSE: Initialize State Machine with the address of the State Table
; INPUT: $FB = State table low byte, $FC = State table high byte
; ----------------------------------------------------------------------------
state_init:
        LDA $FB
        STA mStateTablePtr
        LDA $FC
        STA mStateTablePtr+1
        LDA #STATE_NONE
        STA mCurrentState
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: state_change
; PURPOSE: Transition from current state to a new state
; INPUT: A = new state ID (0 to 6)
; ----------------------------------------------------------------------------
state_change:
        PHA                     ; Save new state ID

        ; 1. Check if there is an active current state to exit
        LDA mCurrentState
        CMP #STATE_NONE
        BEQ _sc_enter_new       ; If no state is active, jump straight to enter

        ; 2. Call EXIT handler of current state
        LDY #STATE_CB_EXIT
        JSR state_invoke_callback

_sc_enter_new:
        ; 3. Update current state to the new state
        PLA                     ; Restore new state ID
        STA mCurrentState

        ; 4. Call ENTER handler of new state
        LDY #STATE_CB_ENTER
        JSR state_invoke_callback
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: state_update
; PURPOSE: Run the update logic for the current state
; ----------------------------------------------------------------------------
state_update:
        LDA mCurrentState
        CMP #STATE_NONE
        BEQ _su_done

        ; Call UPDATE handler of current state
        LDY #STATE_CB_UPDATE
        JSR state_invoke_callback

_su_done:
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: state_draw
; PURPOSE: Run the render logic for the current state
; ----------------------------------------------------------------------------
state_draw:
        LDA mCurrentState
        CMP #STATE_NONE
        BEQ _sd_done

        ; Call DRAW handler of current state
        LDY #STATE_CB_DRAW
        JSR state_invoke_callback

_sd_done:
        RTS

; ----------------------------------------------------------------------------
; HELPER ROUTINES
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; ROUTINE: state_invoke_callback
; PURPOSE: Calculate callback pointer for state ID and offset, then execute if non-null
; INPUT: A = state ID, Y = callback offset (STATE_CB_ENTER, EXIT, UPDATE, DRAW)
; ----------------------------------------------------------------------------
state_invoke_callback:
        STY mCbOffsetTemp
        JSR _sc_calc_state_offset

        ; Add callback offset to zStateTempAddr
        LDY mCbOffsetTemp
        TYA
        CLC
        ADC zStateTempAddr
        STA zStateTempAddr
        LDA zStateTempAddr+1
        ADC #0
        STA zStateTempAddr+1

        ; Load callback pointer
        LDY #0
        LDA (zStateTempAddr),Y
        STA mStateCallPtr
        INY
        LDA (zStateTempAddr),Y
        STA mStateCallPtr+1

        ; Call callback if non-null
        LDA mStateCallPtr
        ORA mStateCallPtr+1
        BEQ _sic_done
        JSR _execute_state_callback

_sic_done:
        RTS

; Calculate state offset: state_id * 8 + mStateTablePtr
; Input: A = state ID
; Output: zStateTempAddr = pointer to state's struct
_sc_calc_state_offset:
        ASL                     ; * 2
        ASL                     ; * 4
        ASL                     ; * 8
        STA mStateTempOffset

        LDA mStateTablePtr
        CLC
        ADC mStateTempOffset
        STA zStateTempAddr
        LDA mStateTablePtr+1
        ADC #0
        STA zStateTempAddr+1
        RTS

_execute_state_callback:
        JMP (mStateCallPtr)

; ----------------------------------------------------------------------------
; STORAGE VARIABLES
; ----------------------------------------------------------------------------
mCurrentState:     .byte $FF
mStateTablePtr:    .word $0000
mStateCallPtr:     .word $0000
mStateTempOffset:  .byte $00
mCbOffsetTemp:     .byte $00
