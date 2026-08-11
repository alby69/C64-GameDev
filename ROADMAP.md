# ROADMAP.md — C64 Game Development Kit (c64kit)
## Refactoring del Repository `alby69/invaders` in Libreria Generalizzata per Giochi C64

> **Destinatario:** Google Jules (Async Coding Agent)
> **Repository:** https://github.com/alby69/invaders
> **Linguaggi:** Python 3.11+, 6502 Assembly (xa65), Makefile
> **Target:** Commodore 64 (PAL/NTSC)
> **Data:** 2026-08-10
> **Priorità:** Critica → Alta → Media → Bassa

---

## 📋 EXECUTIVE SUMMARY

Il repository attuale contiene:
1. **Un porting funzionante** di Space Invaders PET→C64 in assembly modulare (10 file `.asm`)
2. **Una libreria Python `c64kit/`** (15 moduli) che emula l'hardware C64 per testing/verifica
3. **Test pytest** e **documentazione** dettagliata (`DOCUMENTATION.md`)

L'obiettivo è trasformare `c64kit` da **toolkit specifico per Invaders** a **framework generico per sviluppo giochi C64**, con:
- `c64kit/` → libreria Python riutilizzabile per qualsiasi gioco C64
- `c64lib/` → libreria assembly 6502 modulare per qualsiasi gioco C64
- `games/invaders/` → Space Invaders como primo gioco dimostrativo
- `games/template/` → template minimo per nuovi giochi

---

## 🎯 STATUS DELLE FASI

### 🎯 PHASE 1 — Foundation: Estrarre Core Generico Python
**Status: 100% COMPLETATA**
Hardware emulation, ROM banking, CIA timers, priority IRQ/NMI scheduler, VIC-II, SID structure, dual joystick and fully scanned keyboard mapping are completed and verified.

### 🎯 PHASE 2 — Game Framework: Engine Python Riutilizzabile
**Status: 100% COMPLETATA**
Delivers a reusable game framework containing Finite State Machine, char-based and hardware Sprite Engine with dirty-rectangle optimization, Spatial Hash Grid collision system, and BCD Score/HUD manager.

### 🎯 PHASE 3 — Python Toolkit: Build, Asset, Test
**Status: 100% COMPLETATA**
Pipeline tools (asset converter, sfx compiler, python build scheduler, and VICE headless test harness) are fully operational and verified.

### 🎯 PHASE 4 — Refactoring Assembly: `c64lib/`
**Status: 100% COMPLETATA**
Core hardware abstractions (HAL), zero-page memory allocator, custom charset copy, SID voice ADSR handlers, unified joystick movement, and custom interval IRQ scheduler are implemented under `c64lib/core/`.

### 🎯 PHASE 5 — Game Framework Assembly: `c64lib/game/`
**Status: 100% COMPLETATA**
Game state callback tables, sprite drawing engines, collision detector buffers, and BCD score unboxing display registers are fully implemented under `c64lib/game/`.

### 🎯 PHASE 6 — Refactoring Space Invaders
**Status: 100% COMPLETATA**
Refactored Space Invaders inside `games/invaders/` into structured state callbacks and decoupled entity modules.
- **Task 6.1 — Portare Invaders su c64lib**: Created the decoupled workspace and included c64lib modules.
- **Task 6.2 — Rimuovere Self-Modifying Code**: Replaced all inline self-modifications in `invader.asm` with standard RAM variables (`mInvaderSpeedDelay`, `mMaxMissiles`) for full ROM-compatibility.
- **Task 6.3 — Generalizzare Level Data**: Formulated standard level configurations structure inside `level_data.asm`.

### 🎯 PHASE 7 — Developer Experience & Documentazione
**Status: 100% COMPLETATA**
- **Task 7.1 — Template Nuovo Gioco**: Developed and verified a template game in `games/template/` along with `./new_game.sh` setup tool.
- **Task 7.2 — Documentazione API**: Created assembly API (`docs/ASSEMBLY_API.md`) and Python API (`docs/PYTHON_API.md`) documentations.
- **Task 7.3 — Tutorial "Primo Gioco in 30 Minuti"**: Created step-by-step developer tutorial (`docs/TUTORIAL_30MIN.md`) and memory allocations guide (`docs/MEMORY_MAP.md`).

### 🎯 PHASE 8 — Ottimizzazioni Avanzate
**Status: In Progress / Future Plan**
Refining multiplexing techniques and cartridges build automation targets.
