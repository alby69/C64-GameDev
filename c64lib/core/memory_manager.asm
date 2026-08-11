; ============================================================================
; MODULE: memory_manager.asm
; PURPOSE: Zero page allocation tracker and basic memory configuration
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y, SR
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Zero page allocation tracker
; Declared in standard memory space to avoid KERNAL Page 2 conflicts
ZP_ALLOC_TABLE:
        .dsb 32, 0

ZP_USER_START  = $10    ; $10-$CF allocabile
ZP_USER_END    = $CF

MEMORY_SCREEN  = $0400
MEMORY_COLOR   = $D800
MEMORY_CHARSET = $3800
MEMORY_SPRITE  = $2000

; Temporary storage on ZP for allocation logic (using $FB-$FF)
ZP_ALLOC_TEMP_N = $FB
ZP_ALLOC_TEMP_X = $FC
ZP_ALLOC_TEMP_Y = $FD

; ----------------------------------------------------------------------------
; ROUTINE: zp_alloc
; PURPOSE: Allocate A consecutive zero page bytes
; INPUT: A = bytes needed (e.g., 2, 4, 6, 8)
; OUTPUT: X = start ZP address ($10-$CF), Carry=1 if ok, Carry=0 if failed
; ----------------------------------------------------------------------------
zp_alloc:
        STA ZP_ALLOC_TEMP_N     ; Store requested number of bytes
        LDA #$00
        STA ZP_ALLOC_TEMP_X     ; Current search index (0 to 191)

_zp_alloc_search_loop:
        ; Check if search index exceeds max allocatable (192)
        LDA ZP_ALLOC_TEMP_X
        CLC
        ADC ZP_ALLOC_TEMP_N
        CMP #192                ; 192 = $C0 bytes
        BCS _zp_alloc_fail      ; Not enough space remaining

        ; Check if N consecutive bits are free starting at ZP_ALLOC_TEMP_X
        LDY #0                  ; offset from ZP_ALLOC_TEMP_X
_zp_alloc_check_loop:
        TYA
        CLC
        ADC ZP_ALLOC_TEMP_X
        JSR _zp_is_bit_set
        BCS _zp_alloc_check_failed ; If bit is set, we can't start here

        INY
        CPY ZP_ALLOC_TEMP_N
        BNE _zp_alloc_check_loop

        ; Found consecutive bits! Let's mark them as allocated.
        LDY #0
_zp_alloc_mark_loop:
        TYA
        CLC
        ADC ZP_ALLOC_TEMP_X
        JSR _zp_set_bit
        INY
        CPY ZP_ALLOC_TEMP_N
        BNE _zp_alloc_mark_loop

        ; Success! Start ZP address = ZP_USER_START + index
        LDA ZP_ALLOC_TEMP_X
        CLC
        ADC #ZP_USER_START
        TAX                     ; X = start index (ZP address)
        SEC                     ; Carry = 1 (ok)
        RTS

_zp_alloc_check_failed:
        ; Move search index forward by 1
        INC ZP_ALLOC_TEMP_X
        JMP _zp_alloc_search_loop

_zp_alloc_fail:
        LDX #$00
        CLC                     ; Carry = 0 (fail)
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: zp_free
; PURPOSE: Free zero page block starting at X
; INPUT: X = start ZP address, A = bytes to free
; OUTPUT: None
; ----------------------------------------------------------------------------
zp_free:
        STA ZP_ALLOC_TEMP_N     ; Store bytes to free
        TXA
        SEC
        SBC #ZP_USER_START      ; Convert ZP address to bit index (0-191)
        STA ZP_ALLOC_TEMP_X

        LDY #0
_zp_free_loop:
        TYA
        CLC
        ADC ZP_ALLOC_TEMP_X
        JSR _zp_clear_bit
        INY
        CPY ZP_ALLOC_TEMP_N
        BNE _zp_free_loop
        RTS

; ----------------------------------------------------------------------------
; HELPER ROUTINES FOR BIT MANIPULATION
; ----------------------------------------------------------------------------

; Input: A = bit index (0 to 191)
; Output: Carry = bit value (0 or 1)
_zp_is_bit_set:
        PHA
        AND #$07                ; Bit offset (0 to 7)
        TAY
        PLA
        LSR
        LSR
        LSR                     ; Byte offset (0 to 23)
        TAX
        LDA ZP_ALLOC_TABLE,X
        AND _zp_bit_masks,Y
        BNE _zp_bit_is_1
        CLC
        RTS
_zp_bit_is_1:
        SEC
        RTS

; Input: A = bit index (0 to 191)
_zp_set_bit:
        PHA
        AND #$07
        TAY
        PLA
        LSR
        LSR
        LSR
        TAX
        LDA ZP_ALLOC_TABLE,X
        ORA _zp_bit_masks,Y
        STA ZP_ALLOC_TABLE,X
        RTS

; Input: A = bit index (0 to 191)
_zp_clear_bit:
        PHA
        AND #$07
        TAY
        PLA
        LSR
        LSR
        LSR
        TAX
        LDA ZP_ALLOC_TABLE,X
        AND _zp_bit_inv_masks,Y
        STA ZP_ALLOC_TABLE,X
        RTS

_zp_bit_masks:
        .byte $01, $02, $04, $08, $10, $20, $40, $80

_zp_bit_inv_masks:
        .byte $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F
