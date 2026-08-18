; ============================================================================
; MODULE: collision_system.asm
; PURPOSE: Axis-Aligned Bounding Box (AABB) Collision Detection System
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y, SR
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Object Offsets
OBJ_ACTIVE = 0
OBJ_ID     = 1
OBJ_X      = 2
OBJ_Y      = 3
OBJ_W      = 4
OBJ_H      = 5
OBJ_TYPE   = 6
OBJ_SIZE   = 7

; Configuration Constants
MAX_COLLISION_OBJECTS = 24
MAX_COLLISIONS        = 16

; Zero Page Temporary Variables
; Using ZFB/ZFC range which is standard ($FB-$FC)
zColTempX = $FB
zColTempY = $FC

; ----------------------------------------------------------------------------
; ROUTINE: collision_init
; PURPOSE: Reset the collision system, clearing all objects and buffers
; ----------------------------------------------------------------------------
collision_init:
        LDX #0
        LDA #0
_col_init_loop:
        STA OBJECTS_TABLE+OBJ_ACTIVE,X
        TXA
        CLC
        ADC #OBJ_SIZE
        TAX
        CMP #(MAX_COLLISION_OBJECTS * OBJ_SIZE)
        BCC _col_init_loop

        LDA #$FF
        STA COLLISION_BUFFER    ; Terminate empty buffer
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: collision_add
; PURPOSE: Register an object for collision checks
; INPUT: A = id, X = x, Y = y, $FB = w, $FC = h, $10 = type
; OUTPUT: Carry = 1 if added, 0 if table full
; ----------------------------------------------------------------------------
collision_add:
        STA mColAddID
        STX mColAddX
        STY mColAddY

        ; Find free slot (active = 0)
        LDX #0
_col_add_find:
        LDA OBJECTS_TABLE+OBJ_ACTIVE,X
        BEQ _col_add_found
        TXA
        CLC
        ADC #OBJ_SIZE
        TAX
        CMP #(MAX_COLLISION_OBJECTS * OBJ_SIZE)
        BCC _col_add_find

        ; No slot available
        CLC                     ; Carry = 0 (Fail)
        RTS

_col_add_found:
        LDA #1
        STA OBJECTS_TABLE+OBJ_ACTIVE,X
        LDA mColAddID
        STA OBJECTS_TABLE+OBJ_ID,X
        LDA mColAddX
        STA OBJECTS_TABLE+OBJ_X,X
        LDA mColAddY
        STA OBJECTS_TABLE+OBJ_Y,X
        LDA $FB                 ; Width
        STA OBJECTS_TABLE+OBJ_W,X
        LDA $FC                 ; Height
        STA OBJECTS_TABLE+OBJ_H,X
        LDA $10                 ; Type
        STA OBJECTS_TABLE+OBJ_TYPE,X

        SEC                     ; Carry = 1 (Success)
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: collision_remove
; PURPOSE: Remove an object by its ID
; INPUT: A = id
; ----------------------------------------------------------------------------
collision_remove:
        STA mColRemoveID
        LDX #0
_col_rem_loop:
        LDA OBJECTS_TABLE+OBJ_ACTIVE,X
        BEQ _col_rem_next
        LDA OBJECTS_TABLE+OBJ_ID,X
        CMP mColRemoveID
        BNE _col_rem_next

        ; Match found, deactivate slot
        LDA #0
        STA OBJECTS_TABLE+OBJ_ACTIVE,X
        RTS

_col_rem_next:
        TXA
        CLC
        ADC #OBJ_SIZE
        TAX
        CMP #(MAX_COLLISION_OBJECTS * OBJ_SIZE)
        BCC _col_rem_loop
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: collision_check_pair
; PURPOSE: Check collision between object in slot X and slot Y
; INPUT: X = object 1 offset, Y = object 2 offset (0 to MAX_OBJECTS * OBJ_SIZE)
; OUTPUT: Carry = 1 if colliding, 0 if not
; ----------------------------------------------------------------------------
collision_check_pair:
        ; Compare X-axis
        LDA OBJECTS_TABLE+OBJ_X,X
        CLC
        ADC OBJECTS_TABLE+OBJ_W,X
        CMP OBJECTS_TABLE+OBJ_X,Y
        BCC _ccp_no_col
        BEQ _ccp_no_col

        LDA OBJECTS_TABLE+OBJ_X,Y
        CLC
        ADC OBJECTS_TABLE+OBJ_W,Y
        CMP OBJECTS_TABLE+OBJ_X,X
        BCC _ccp_no_col
        BEQ _ccp_no_col

        ; Compare Y-axis
        LDA OBJECTS_TABLE+OBJ_Y,X
        CLC
        ADC OBJECTS_TABLE+OBJ_H,X
        CMP OBJECTS_TABLE+OBJ_Y,Y
        BCC _ccp_no_col
        BEQ _ccp_no_col

        LDA OBJECTS_TABLE+OBJ_Y,Y
        CLC
        ADC OBJECTS_TABLE+OBJ_H,Y
        CMP OBJECTS_TABLE+OBJ_Y,X
        BCC _ccp_no_col
        BEQ _ccp_no_col

        ; Overlap detected!
        SEC
        RTS
_ccp_no_col:
        CLC
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: collision_check_all
; PURPOSE: Detect all collisions and populate COLLISION_BUFFER
; ----------------------------------------------------------------------------
collision_check_all:
        LDA #0
        STA mBufferIndex

        ; Reset buffer
        LDA #$FF
        STA COLLISION_BUFFER

        ; Double loop to check all pairs X and Y
        ; Outer loop index = mOuterOffset (0 to (MAX_OBJECTS - 2) * OBJ_SIZE)
        ; Inner loop index = mInnerOffset (mOuterOffset + OBJ_SIZE to (MAX_OBJECTS - 1) * OBJ_SIZE)
        LDA #0
        STA mOuterOffset

_cca_outer_loop:
        LDX mOuterOffset
        LDA OBJECTS_TABLE+OBJ_ACTIVE,X
        BEQ _cca_outer_next     ; Skip if outer slot is inactive

        ; Inner loop starts at mOuterOffset + OBJ_SIZE
        TXA
        CLC
        ADC #OBJ_SIZE
        STA mInnerOffset

_cca_inner_loop:
        LDY mInnerOffset
        LDA OBJECTS_TABLE+OBJ_ACTIVE,Y
        BEQ _cca_inner_next     ; Skip if inner slot is inactive

        ; Perform check
        LDX mOuterOffset
        ; X and Y registers are ready
        JSR collision_check_pair
        BCC _cca_inner_next     ; No collision, proceed

        ; Collision detected! Add pair to buffer
        LDX mOuterOffset
        LDY mInnerOffset
        LDA OBJECTS_TABLE+OBJ_ID,X
        STA mColTempID1
        LDA OBJECTS_TABLE+OBJ_ID,Y
        STA mColTempID2

        ; Store in buffer: (mColTempID1, mColTempID2)
        LDX mBufferIndex
        CPX #(MAX_COLLISIONS * 2)
        BCS _cca_buffer_full    ; Avoid overflowing collision buffer

        LDA mColTempID1
        STA COLLISION_BUFFER,X
        INX
        LDA mColTempID2
        STA COLLISION_BUFFER,X
        INX
        STX mBufferIndex

        ; Place terminator at the new index
        LDA #$FF
        STA COLLISION_BUFFER,X

_cca_inner_next:
        LDA mInnerOffset
        CLC
        ADC #OBJ_SIZE
        STA mInnerOffset
        CMP #(MAX_COLLISION_OBJECTS * OBJ_SIZE)
        BCC _cca_inner_loop

_cca_outer_next:
        LDA mOuterOffset
        CLC
        ADC #OBJ_SIZE
        STA mOuterOffset
        CMP #((MAX_COLLISION_OBJECTS - 1) * OBJ_SIZE)
        BCC _cca_outer_loop

_cca_buffer_full:
        RTS

; ----------------------------------------------------------------------------
; STORAGE VARIABLES
; ----------------------------------------------------------------------------
mColAddID:        .byte $00
mColAddX:         .byte $00
mColAddY:         .byte $00
mColRemoveID:     .byte $00

mOuterOffset:     .byte $00
mInnerOffset:     .byte $00
mBufferIndex:     .byte $00

mColTempID1:      .byte $00
mColTempID2:      .byte $00

; Statically allocated tables
OBJECTS_TABLE:
        .dsb (MAX_COLLISION_OBJECTS * OBJ_SIZE), 0

COLLISION_BUFFER:
        .dsb (MAX_COLLISIONS * 2 + 1), 0
