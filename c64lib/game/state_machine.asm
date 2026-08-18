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

        ; 2. Call EXIT handler of current state (offset = state_id * 8 + 2)
        JSR _sc_calc_state_offset
        ; Add 2 for EXIT callback offset
        LDA zStateTempAddr
        CLC
        ADC #2
        STA zStateTempAddr
        LDA zStateTempAddr+1
        ADC #0
        STA zStateTempAddr+1

        ; Load EXIT pointer
        LDY #0
        LDA (zStateTempAddr),Y
        STA mStateCallPtr
        INY
        LDA (zStateTempAddr),Y
        STA mStateCallPtr+1

        ; Call exit callback if not null
        LDA mStateCallPtr
        ORA mStateCallPtr+1
        BEQ _sc_enter_new
        JSR _execute_state_callback

_sc_enter_new:
        ; 3. Update current state to the new state
        PLA                     ; Restore new state ID
        STA mCurrentState
        PHA                     ; Keep on stack for enter callback

        ; 4. Call ENTER handler of new state (offset = state_id * 8 + 0)
        LDA mCurrentState
        JSR _sc_calc_state_offset

        ; Load ENTER pointer
        LDY #0
        LDA (zStateTempAddr),Y
        STA mStateCallPtr
        INY
        LDA (zStateTempAddr),Y
        STA mStateCallPtr+1

        ; Call enter callback if not null
        LDA mStateCallPtr
        ORA mStateCallPtr+1
        BEQ _sc_done
        JSR _execute_state_callback

_sc_done:
        PLA                     ; Restore stack
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: state_update
; PURPOSE: Run the update logic for the current state
; ----------------------------------------------------------------------------
state_update:
        LDA mCurrentState
        CMP #STATE_NONE
        BEQ _su_done

        ; Call UPDATE handler of current state (offset = state_id * 8 + 4)
        JSR _sc_calc_state_offset
        LDA zStateTempAddr
        CLC
        ADC #4
        STA zStateTempAddr
        LDA zStateTempAddr+1
        ADC #0
        STA zStateTempAddr+1

        ; Load UPDATE pointer
        LDY #0
        LDA (zStateTempAddr),Y
        STA mStateCallPtr
        INY
        LDA (zStateTempAddr),Y
        STA mStateCallPtr+1

        ; Call update callback if not null
        LDA mStateCallPtr
        ORA mStateCallPtr+1
        BEQ _su_done
        JSR _execute_state_callback

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

        ; Call DRAW handler of current state (offset = state_id * 8 + 6)
        JSR _sc_calc_state_offset
        LDA zStateTempAddr
        CLC
        ADC #6
        STA zStateTempAddr
        LDA zStateTempAddr+1
        ADC #0
        STA zStateTempAddr+1

        ; Load DRAW pointer
        LDY #0
        LDA (zStateTempAddr),Y
        STA mStateCallPtr
        INY
        LDA (zStateTempAddr),Y
        STA mStateCallPtr+1

        ; Call draw callback if not null
        LDA mStateCallPtr
        ORA mStateCallPtr+1
        BEQ _sd_done
        JSR _execute_state_callback

_sd_done:
        RTS

; ----------------------------------------------------------------------------
; HELPER ROUTINES
; ----------------------------------------------------------------------------

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
