; ****************************************************************************
; main.asm -- Entry point for C64 Space Invaders using c64lib
; ****************************************************************************

; Include hardware registers & standard macro helpers
#include "c64lib/hal/c64_hardware.inc"

; ============================================================================
; BASIC LOADER C64
; ============================================================================
* = $0801
.word $080B, 10        ; Line 10
.byte $9E              ; SYS
.asc " 2062", $00      ; SYS 2062 -> $080E
.byte $00, $00

; Entry point from BASIC loader
START:
        ; Reset memory configurations and system drivers
        jsr vic_init
        jsr sid_init
        jsr input_init
        jsr irq_init

        ; Initialize state machine
        lda #<STATE_TABLE
        sta $FB
        lda #>STATE_TABLE
        sta $FC
        jsr state_init

        ; Change to initial state (BOOT)
        lda #STATE_BOOT
        jsr state_change

MAIN_LOOP:
        ; Run game tick
        jsr state_update
        jsr state_draw
        jsr irq_wait_vsync
        jmp MAIN_LOOP

; ============================================================================
; MODULES INCLUSION (c64lib core and game subsystems)
; ============================================================================
#include "c64lib/core/memory_manager.asm"
#include "c64lib/core/vic_engine.asm"
#include "c64lib/core/sid_engine.asm"
#include "c64lib/core/input_system.asm"
#include "c64lib/core/irq_scheduler.asm"
#include "c64lib/game/state_machine.asm"
#include "c64lib/game/sprite_engine.asm"
#include "c64lib/game/collision_system.asm"
#include "c64lib/game/hud_system.asm"

; Include custom states
#include "game_states/state_boot.asm"
#include "game_states/state_title.asm"
#include "game_states/state_menu.asm"
#include "game_states/state_play.asm"
#include "game_states/state_pause.asm"
#include "game_states/state_gameover.asm"

; Include custom entities
#include "entities/player.asm"
#include "entities/invader.asm"
#include "entities/missile.asm"
#include "entities/bunker.asm"
#include "entities/bonus.asm"

; Include game data configurations
#include "data/level_data.asm"
#include "data/sprite_data.asm"
#include "data/sfx_data.asm"
