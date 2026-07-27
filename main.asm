; ****************************************************************************
; main.asm -- Entry point, init, game loop
; ****************************************************************************
; Purpose: Main entry point for Commodore 64 Space Invaders. Sets up the
; BASIC loader stub, incorporates logical modules, and coordinates execution.
; ****************************************************************************

; Centralized memory map and register definitions
#include "memory.inc"

; ============================================================================
; BASIC LOADER C64
; ============================================================================
* = $0801
.word $080B, 10        ; Line 10
.byte $9E              ; SYS
.asc " 2062", $00      ; SYS 2062 -> $080E
.byte $00, $00

; ============================================================================
; MODULES INCLUSION (Ordered to preserve exact contiguous binary structure)
; ============================================================================

#include "video_init.asm"
#include "game_loop.asm"
#include "video_interrupts.asm"
#include "sound_step.asm"
#include "input_movement.asm"
#include "game_logic_1.asm"
#include "video_raster.asm"
#include "game_logic_2.asm"
#include "data.asm"
