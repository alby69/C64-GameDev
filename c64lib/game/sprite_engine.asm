; ============================================================================
; MODULE: sprite_engine.asm
; PURPOSE: Character-based and VIC-II Hardware Sprite Engine
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y, SR
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; Struct Offsets for SPRITE_DEF
SPRITE_X      = 0       ; 1 byte
SPRITE_Y      = 1       ; 1 byte
SPRITE_WIDTH  = 2       ; 1 byte (in chars for char, in pixels or index for HW)
SPRITE_HEIGHT = 3       ; 1 byte (in chars for char, in pixels or index for HW)
SPRITE_FRAME  = 4       ; 1 byte
SPRITE_FLAGS  = 5       ; 1 byte: Bit 7=active, 6=hw_sprite, 5=multicolor, 4-0=color/ID
SPRITE_DATA_L = 6       ; 1 byte (Low byte of pointer)
SPRITE_DATA_H = 7       ; 1 byte (High byte of pointer)

; Zero Page pointers used for indirect indexing
zSprPtr       = $FB     ; Pointer to SPRITE_DEF struct (passed in ZFB)
zScreenDest   = $FD     ; Pointer to Screen RAM target
zColorDest    = $10     ; Pointer to Color RAM target
zDataSrc      = $12     ; Pointer to frame data source

; ----------------------------------------------------------------------------
; ROUTINE: sprite_draw
; PURPOSE: Draw sprite based on its definition (character or hardware)
; INPUT: zSprPtr = pointer to SPRITE_DEF
; ----------------------------------------------------------------------------
sprite_draw:
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$40                ; Check bit 6 (hw_sprite)
        BEQ _sd_char_sprite
        JMP _sd_hw_sprite

_sd_char_sprite:
        ; --- Character-Based Sprite Drawing ---
        ; 1. Calculate source address: data_ptr + (frame * width * height)
        LDY #SPRITE_DATA_L
        LDA (zSprPtr),Y
        STA zDataSrc
        LDY #SPRITE_DATA_H
        LDA (zSprPtr),Y
        STA zDataSrc+1

        ; Calculate frame offset = frame * width * height
        LDY #SPRITE_FRAME
        LDA (zSprPtr),Y
        BEQ _sd_calc_screen     ; If frame is 0, no offset calculation needed

        STA mSprTempFrame
        LDY #SPRITE_WIDTH
        LDA (zSprPtr),Y
        STA mSprTempWidth
        LDY #SPRITE_HEIGHT
        LDA (zSprPtr),Y
        ; Multiply frame * width * height
        ; Simply loop add: frame times (width * height)
        TAX
        LDA #0
_sd_mult_height:
        CLC
        ADC mSprTempWidth
        DEX
        BNE _sd_mult_height
        ; Now A = width * height
        ; Now multiply by frame (mSprTempFrame)
        LDX mSprTempFrame
        STA mSprTempWidth       ; temporary store (width * height)
        LDA #0
_sd_mult_frame:
        CLC
        ADC mSprTempWidth
        DEX
        BNE _sd_mult_frame

        ; Add offset to zDataSrc
        CLC
        ADC zDataSrc
        STA zDataSrc
        LDA #0
        ADC zDataSrc+1
        STA zDataSrc+1

_sd_calc_screen:
        ; 2. Calculate Screen RAM and Color RAM target addresses
        ; Target = SCREEN_MEM + (Y * 40) + X
        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        JSR _spr_calc_screen_addr

        ; Offset by X
        LDY #SPRITE_X
        LDA (zSprPtr),Y
        CLC
        ADC zScreenDest
        STA zScreenDest
        LDA #0
        ADC zScreenDest+1
        STA zScreenDest+1

        ; Color RAM has identical offset, just base $D800 instead of $0400
        LDA zScreenDest
        STA zColorDest
        LDA zScreenDest+1
        AND #$03                ; Keep offset within 1KB
        ORA #$D8                ; Base $D800
        STA zColorDest+1

        ; 3. Draw character matrix
        LDY #SPRITE_HEIGHT
        LDA (zSprPtr),Y
        STA mSprTempHeight      ; Row counter
        LDY #SPRITE_WIDTH
        LDA (zSprPtr),Y
        STA mSprTempWidth       ; Col counter

        LDA #0
        STA mSprSrcOffset       ; Source data offset
        STA mSprDestOffset      ; Destination screen offset

_sd_row_loop:
        LDX #0                  ; Col index
_sd_col_loop:
        ; Load character
        LDY mSprSrcOffset
        LDA (zDataSrc),Y

        ; Store character to screen
        LDY mSprDestOffset
        STA (zScreenDest),Y

        ; Store color to Color RAM (lower 4 bits of SPRITE_FLAGS)
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$0F                ; Color bits
        LDY mSprDestOffset
        STA (zColorDest),Y

        INC mSprSrcOffset
        INC mSprDestOffset

        INX
        CPX mSprTempWidth
        BNE _sd_col_loop

        ; Move destination to next screen row (add 40, subtract width)
        LDA mSprDestOffset
        CLC
        ADC #40
        SEC
        SBC mSprTempWidth
        STA mSprDestOffset

        DEC mSprTempHeight
        BNE _sd_row_loop
        RTS

_sd_hw_sprite:
        ; --- Hardware Sprite Drawing ---
        ; Sprite ID is stored in lower 3 bits of flags
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$07                ; Sprite ID (0 to 7)
        STA mSprTempID
        TAX                     ; X = ID

        ; Enable Sprite
        LDA _spr_bit_masks,X
        ORA VIC_SPR_EN
        STA VIC_SPR_EN

        ; Set Multi-color option
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$20                ; Bit 5
        BEQ _sd_hw_single
        ; Multi-color
        LDA _spr_bit_masks,X
        ORA VIC_SPR_MC
        STA VIC_SPR_MC
        JMP _sd_hw_pos
_sd_hw_single:
        LDA _spr_bit_masks,X
        EOR #$FF
        AND VIC_SPR_MC
        STA VIC_SPR_MC

_sd_hw_pos:
        ; Set X, Y positions
        LDY #SPRITE_X
        LDA (zSprPtr),Y
        STA mSprTempX
        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        STA mSprTempY

        ; Calculate hardware positions and write to VIC
        LDX mSprTempID
        TXA
        ASL                     ; ID * 2
        TAX
        LDA mSprTempX
        STA VIC_SPR0_X,X
        LDA mSprTempY
        STA VIC_SPR0_X+1,X      ; Y coordinate is next register

        ; Set Sprite Color
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$0F                ; Color
        LDX mSprTempID
        STA VIC_SPR_COL0,X      ; Sprite color register

        ; Set Sprite Pointer in Screen Memory (at SCREEN_MEM + $3F8 + ID)
        LDY #SPRITE_DATA_H
        LDA (zSprPtr),Y
        STA mSprTempPtrH
        LDY #SPRITE_DATA_L
        LDA (zSprPtr),Y
        STA mSprTempPtrL

        ; Pointer value = (Address - VIC_BANK_BASE) / 64
        ; For simplicity, assume VIC Bank 0 (base $0000)
        ; pointer = (H * 256 + L) / 64 = H * 4 + L / 64
        ; Let's shift the address right 6 times
        LDA mSprTempPtrL
        LSR mSprTempPtrH
        ROR
        LSR mSprTempPtrH
        ROR
        LSR mSprTempPtrH
        ROR
        LSR mSprTempPtrH
        ROR
        LSR mSprTempPtrH
        ROR
        LSR mSprTempPtrH
        ROR
        STA mSprTempPtrL        ; Pointer value

        LDX mSprTempID
        LDA mSprTempPtrL
        STA SCREEN_MEM+$03F8,X  ; Write pointer to Screen Pointer slot
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sprite_clear
; PURPOSE: Clear character-based sprite or disable hardware sprite
; INPUT: zSprPtr = pointer to SPRITE_DEF
; ----------------------------------------------------------------------------
sprite_clear:
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$40
        BEQ _sc_char_clear
        JMP _sc_hw_clear

_sc_char_clear:
        ; --- Character-Based Sprite Clearing ---
        ; 1. Calculate Target screen address
        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        JSR _spr_calc_screen_addr

        LDY #SPRITE_X
        LDA (zSprPtr),Y
        CLC
        ADC zScreenDest
        STA zScreenDest
        LDA #0
        ADC zScreenDest+1
        STA zScreenDest+1

        ; 2. Overwrite with space character ($20)
        LDY #SPRITE_HEIGHT
        LDA (zSprPtr),Y
        STA mSprTempHeight
        LDY #SPRITE_WIDTH
        LDA (zSprPtr),Y
        STA mSprTempWidth

        LDA #0
        STA mSprDestOffset

_sc_row_loop:
        LDX #0
_sc_col_loop:
        LDA #$20                ; Space character
        LDY mSprDestOffset
        STA (zScreenDest),Y
        INC mSprDestOffset

        INX
        CPX mSprTempWidth
        BNE _sc_col_loop

        ; Move destination to next row
        LDA mSprDestOffset
        CLC
        ADC #40
        SEC
        SBC mSprTempWidth
        STA mSprDestOffset

        DEC mSprTempHeight
        BNE _sc_row_loop
        RTS

_sc_hw_clear:
        ; --- Disable Hardware Sprite ---
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$07                ; ID (0 to 7)
        TAX
        LDA _spr_bit_masks,X
        EOR #$FF
        AND VIC_SPR_EN
        STA VIC_SPR_EN
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sprite_animate
; PURPOSE: Set active frame of sprite
; INPUT: zSprPtr = pointer to SPRITE_DEF, A = frame
; ----------------------------------------------------------------------------
sprite_animate:
        LDY #SPRITE_FRAME
        STA (zSprPtr),Y
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sprite_move
; PURPOSE: Add relative offset to sprite position
; INPUT: zSprPtr = pointer to SPRITE_DEF, A = delta X, X = delta Y
; ----------------------------------------------------------------------------
sprite_move:
        STA mSprTempDX
        STX mSprTempDY

        LDY #SPRITE_X
        LDA (zSprPtr),Y
        CLC
        ADC mSprTempDX
        STA (zSprPtr),Y

        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        CLC
        ADC mSprTempDY
        STA (zSprPtr),Y
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: sprite_clip
; PURPOSE: Clip sprite within screen boundaries
; INPUT: zSprPtr = pointer to SPRITE_DEF
; ----------------------------------------------------------------------------
sprite_clip:
        LDY #SPRITE_FLAGS
        LDA (zSprPtr),Y
        AND #$40
        BEQ _scl_char_clip
        JMP _scl_hw_clip

_scl_char_clip:
        ; --- Character Sprite Clipping ---
        ; Clip X: 0 <= X <= 40 - Width
        LDY #SPRITE_X
        LDA (zSprPtr),Y
        BPL _scl_char_x_max
        LDA #0
        STA (zSprPtr),Y
_scl_char_x_max:
        LDY #SPRITE_WIDTH
        LDA (zSprPtr),Y
        STA mSprTempWidth
        LDA #40
        SEC
        SBC mSprTempWidth
        STA mSprTempMax         ; Max X

        LDY #SPRITE_X
        LDA (zSprPtr),Y
        CMP mSprTempMax
        BCC _scl_char_y_min
        LDA mSprTempMax
        STA (zSprPtr),Y

_scl_char_y_min:
        ; Clip Y: 0 <= Y <= 25 - Height
        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        BPL _scl_char_y_max
        LDA #0
        STA (zSprPtr),Y
_scl_char_y_max:
        LDY #SPRITE_HEIGHT
        LDA (zSprPtr),Y
        STA mSprTempHeight
        LDA #25
        SEC
        SBC mSprTempHeight
        STA mSprTempMax         ; Max Y

        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        CMP mSprTempMax
        BCC _scl_done
        LDA mSprTempMax
        STA (zSprPtr),Y
_scl_done:
        RTS

_scl_hw_clip:
        ; --- Hardware Sprite Clipping ---
        ; For simplicity, hardware coordinates are clipped to:
        ; 24 <= X <= 320
        ; 50 <= Y <= 240
        LDY #SPRITE_X
        LDA (zSprPtr),Y
        CMP #24
        BCS _scl_hw_x_max
        LDA #24
        STA (zSprPtr),Y
_scl_hw_x_max:
        LDA (zSprPtr),Y
        CMP #244                ; 244 max to avoid overflow/MSB simple handling
        BCC _scl_hw_y_min
        LDA #244
        STA (zSprPtr),Y

_scl_hw_y_min:
        LDY #SPRITE_Y
        LDA (zSprPtr),Y
        CMP #50
        BCS _scl_hw_y_max
        LDA #50
        STA (zSprPtr),Y
_scl_hw_y_max:
        LDA (zSprPtr),Y
        CMP #240
        BCC _scl_hw_done
        LDA #240
        STA (zSprPtr),Y
_scl_hw_done:
        RTS

; ----------------------------------------------------------------------------
; HELPER: _spr_calc_screen_addr
; PURPOSE: Calculate screen RAM start row address (base $0400)
; INPUT: A = Y coordinate (row 0 to 24)
; OUTPUT: zScreenDest = SCREEN_MEM + Y * 40
; ----------------------------------------------------------------------------
_spr_calc_screen_addr:
        PHA
        LDA #<SCREEN_MEM
        STA zScreenDest
        LDA #>SCREEN_MEM
        STA zScreenDest+1
        PLA

        TAY
        BEQ _scsa_done          ; If Y=0, screen RAM is exactly base $0400
_scsa_loop:
        LDA zScreenDest
        CLC
        ADC #40
        STA zScreenDest
        LDA zScreenDest+1
        ADC #0
        STA zScreenDest+1
        DEY
        BNE _scsa_loop
_scsa_done:
        RTS

; ----------------------------------------------------------------------------
; STORAGE VARIABLES
; ----------------------------------------------------------------------------
_spr_bit_masks:
        .byte $01, $02, $04, $08, $10, $20, $40, $80

mSprTempFrame:     .byte $00
mSprTempWidth:     .byte $00
mSprTempHeight:    .byte $00
mSprTempID:        .byte $00
mSprTempX:         .byte $00
mSprTempY:         .byte $00
mSprTempPtrL:      .byte $00
mSprTempPtrH:      .byte $00
mSprTempMax:       .byte $00
mSprTempDX:        .byte $00
mSprTempDY:        .byte $00

mSprSrcOffset:     .byte $00
mSprDestOffset:    .byte $00
