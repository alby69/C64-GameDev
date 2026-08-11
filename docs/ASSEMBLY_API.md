# ASSEMBLY_API.md — c64lib Assembly Library API Reference

This document provides technical documentation for the reusable **6502 assembly components** under `c64lib/`.

---

## 💾 Core Memory Manager (`c64lib/core/memory_manager.asm`)

Manages the Zero Page memory allocation dynamically to prevent collision between distinct game states or subsystems.

### `zp_alloc`
Allocates a block of contiguous Zero Page bytes.
* **Input**: `A` = number of bytes requested (2, 4, 6, 8)
* **Output**: `X` = starting zero-page address, `Carry` = 1 (success), 0 (out of memory)

### `zp_free`
Deallocates a previously allocated Zero Page block.
* **Input**: `X` = starting address of block to free

---

## 📺 Video VIC-II Engine (`c64lib/core/vic_engine.asm`)

Handles initialization, raster wait, screen clearing, custom charset copying, and hardware sprites.

### `vic_init`
Initializes memory pointers for the VIC-II chip, configuring screen bank, charset bank, and standard colors.
* **Input**: `A` = screen memory bank index, `X` = charset bank index, `Y` = border/background color

### `vic_clear_screen`
Clears entire screen memory and clears Color RAM with a specific value.
* **Input**: `A` = fill character, `Y` = fill color

### `vic_wait_raster`
Busy-waits until a specific raster line is being scanned.
* **Input**: `A` = target raster line number

### `vic_copy_charset`
Copies a 2KB custom charset from RAM to character generator bank.
* **Input**: `ZFB`/`ZFC` (Zero Page pointers) = source and target addresses

### `vic_set_sprite_pos`
Updates the X/Y registers of a hardware sprite.
* **Input**: `X` = sprite ID (0-7), `Y` = X coordinate, `A` = Y coordinate

---

## 🎵 Sound SID Engine (`c64lib/core/sid_engine.asm`)

Controls SID registers for 3 voice notes and features a standard SFX play sequencer.

### `sid_init`
Resets all registers on the MOS 6581/8580 SID chip (mutes everything).

### `sid_play_note`
Plays a custom pitch/frequency on an active channel.
* **Input**: `A` = voice channel (0-2), `X` = frequency low byte, `Y` = frequency high byte

### `sid_set_waveform`
Configures control waveform registers.
* **Input**: `A` = channel (0-2), `X` = control waveform byte (e.g. noise=$81, pulse=$41)

### `sid_set_adsr`
Sets Attack/Decay and Sustain/Release values for a specific voice.
* **Input**: `A` = channel (0-2), `X` = Attack/Decay byte, `Y` = Sustain/Release byte

### `sid_play_effect`
Triggers an asynchronous, structured sound effect on Voice 1.
* **Input**: `A` = sound effect ID:
  - `0`: Laser Shoot
  - `1`: Explosion
  - `2`: Step Sound
  - `3`: Bonus UFO
  - `4`: Game Over

---

## 🎮 Input System (`c64lib/core/input_system.asm`)

Provides unified joystick polling and matrix keyboard scan mapping.

### `input_init`
Configures CIA1 DDR registers to read keyboard columns and Joystick Port 2.

### `input_scan_joystick`
Reads direct joystick pin statuses.
* **Input**: `A` = Port (1 or 2)
* **Output**: `A` = Joystick status mask (Bit 4 = Fire, Bit 2 = Left, Bit 3 = Right)

### `input_map_action`
Retrieves a high-level status of whether an action is active (either via joystick or keyboard mapping).
* **Input**: `A` = Action ID:
  - `0` (ACTION_FIRE)
  - `1` (ACTION_LEFT)
  - `2` (ACTION_RIGHT)
  - `3` (ACTION_PAUSE)
  - `4` (ACTION_RESTART)
* **Output**: `A` = `1` (active/pressed), `0` (inactive)

---

## 🔄 Finite State Machine (`c64lib/game/state_machine.asm`)

Manages the decoupled lifecycle states of the game.

### `state_init`
Sets up the state table pointer.
* **Input**: `ZFB`/`ZFC` ($FB/$FC) = state callback table start address

### `state_change`
Changes state, automatically triggering the `EXIT` callback of the old state and `ENTER` of the new state.
* **Input**: `A` = target state ID (0=BOOT, 1=TITLE, 2=MENU, 3=PLAY, 4=PAUSE, 5=GAMEOVER, 6=HIGH)

### `state_update`
Dispatches update ticks to the current state callback.

### `state_draw`
Dispatches redraw ticks to the current state callback.
