# PYTHON_API.md — c64kit Python Emulation API Reference

The `c64kit` package provides a **Python-based high-fidelity emulation environment** for C64 architecture, designed for headless continuous integration testing, verification, and tool-chain compilation.

---

## 🛠️ Memory banking (`c64kit.core.memory`)

Emulates standard Flat 64KB memory space with $01 PLA ROM overlay.

### `C64Memory`
* **`read_byte(addr: int) -> int`**: Reads a byte from memory. Automatically handles ROM banking overlays ($A000-$BFFF, $D000-$DFFF, $E000-$FFFF) depending on PLA register status written at `$01`.
* **`write_byte(addr: int, value: int) -> None`**: Writes a byte to RAM. Writes to ROM addresses do not alter the overlay ROM values.

---

## 📺 VIC-II Video emulation (`c64kit.video.vic`)

Simulates custom charset lookups, screen rendering, raster registers, and hardware sprite control.

### `VICII`
* **`sprite_positions: List[Tuple[int, int]]`**: X and Y coordinates for all 8 VIC hardware sprites.
* **`sprite_enabled: List[bool]`**: Activation status of each sprite.
* **`raster_line: int`**: Simulates scanning beam position. Increments on virtual cycles.

---

## 🔊 SID Synthesis emulation (`c64kit.audio.sid`)

Provides 3-voice ADSR volume and pitch processing.

### `SID`
* **`voices: List[Voice]`**: 3 independent sound channels simulating frequency, envelope (ADSR), and waveforms (sawtooth, triangle, noise, pulse).
* **`get_active_voices() -> int`**: Counts the number of active voices currently playing.

---

## ⌨️ Input scanning (`c64kit.input.keyboard` & `c64kit.input.joystick`)

Simulates hardware keypress matrixes ($DC00/$DC01) and Dual Joysticks.

### `KeyboardMatrix`
* **`press_key(matrix_code: int) -> None`**: Sets key matrix status as pressed.
* **`release_key(matrix_code: int) -> None`**: Clears key matrix status.

---

## 📦 Build Pipeline (`c64kit.build.build_system`)

Automates incremental compilation via `c64project.yaml` specs.

### `build_project(project_path: str, force: bool = False) -> bool`
* Compiles the source using `xa` if files have changed since the last build. Returns `True` on success.
