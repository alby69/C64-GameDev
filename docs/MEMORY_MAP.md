# MEMORY_MAP.md — C64 Space Invaders Memory Layout

This document details the standard C64 memory usage, zero-page pointers, and RAM allocations used by `c64lib` and Space Invaders.

---

## 🗺️ System Memory Layout

| Address Range | Size | Description |
|---------------|------|-------------|
| `$0000 - $00FF` | 256B | Zero Page Memory (used for fast calculations & pointers) |
| `$0100 - $01FF` | 256B | 6502 Stack Space |
| `$0200 - $03FF` | 512B | System variable space, custom tasks queue, interrupt vectors |
| `$0400 - $07FF` | 1024B| Screen RAM (Text / character memory) |
| `$0800 - $0800` | 1B   | BASIC start padding |
| `$0801 - $2FFF` | ~10KB| Compiled game code and binary logic (main entry, states, entities) |
| `$3000 - $37FF` | 2048B| Custom graphics assets / custom charset data |
| `$D800 - $DBFF` | 1024B| VIC-II Color RAM |

---

## ⚡ Zero Page Allocations

Standard zero-page registers used for indirect pointers and temporary parameters:

* **`$FB` / `$FC` (ZFB / ZFC)**: Shared pointers for state machine table addresses, sprite drawing, and custom charset copy routines.
* **`$FD` / `$FE`**: Screen destination row pointer calculations.
* **`$10` / `$11`**: Color RAM destination pointer calculations.
* **`$12` / `$13`**: Sprite data source index offsets.
