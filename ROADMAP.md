# ROADMAP.md — C64 Game Development Kit (c64kit)
## Refactoring del Repository `alby69/C64GameDev` in Libreria Generalizzata per Giochi C64

> **Destinatario:** Google Jules (Async Coding Agent)
> **Repository:** https://github.com/alby69/C64GameDev
> **Linguaggi:** Python 3.11+, 6502 Assembly (xa65), Makefile
> **Target:** Commodore 64 (PAL/NTSC)
> **Data:** 2026-08-10
> **Priorità:** Critica → Alta → Media → Bassa

---

## 📋 EXECUTIVE SUMMARY

Il repository attuale contiene:
1. **Un porting funzionante** di Space Invaders PET→C64 in assembly modulare (10 file `.asm`)
2. **Una libreria Python `c64kit/`** (15 moduli) che emula l'hardware C64 per testing/verifica
3. **Test pytest** e **documentazione** dettagliata (`docs/`, `README.md`)

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

### 🎯 PHASE 8 — Ottimizzazioni Avanzate & Packaging Automation
**Status: 100% COMPLETATA**
- **Task 8.1 — Automazione Build Cartucce e Immagini Disco (.crt, .d64)**: Estesa la pipeline di build in Python (`c64kit/build/build_system.py`) per supportare il packaging nativo delle ROM. Se abilitato in `c64project.yaml`, compila automaticamente sia file cartuccia C64 (`.crt` generati tramite `cartconv`) che immagini floppy disk standard (`.d64` formattate e scritte tramite `c1541`).
- **Task 8.2 — Sprite Multiplexing**: Implementata una libreria generalizzata per sprite multiplexing in `c64lib/game/sprite_engine.asm`, comprensiva di ordinamento dinamico (Bubble Sort ad alta efficienza per 16 sprite virtuali) e mappatura automatica dei primi 8 sprite fisici del VIC-II.

### 🎯 PHASE 9 — Pulizia Repository & Solo-C64
**Status: 100% COMPLETATA**
- **Task 9.1 — Eliminare il Codice PET dalla Root**: Rimossi dalla root tutti i file assembly non-C64. Il disassembly PET originale (`invaders.asm`) è archiviato in `source/pet/` (non compilato), insieme alla sua documentazione tecnica.
- **Task 9.2 — Archiviare il Port Monolitico Legacy**: Il primo port PET→C64 monolitico (`main.asm`, `memory.inc`, `video_*.asm`, `game_*.asm`, `data.asm`, ecc.) — superato da `games/invaders/` basato su `c64lib` — è archiviato in `source/legacy/` come riferimento storico.
- **Task 9.3 — Aggiornamento Tooling e Documentazione**: Il `Makefile` ora delega al build system Python (`games/invaders/c64project.yaml`). README, ROADMAP e TUTORIAL aggiornati per riflettere la struttura definitiva.
- **Task 9.4 — Verifica Solo-C64**: Nessun residuo di indirizzi hardware PET (`$E8xx`, `$8000`, vettori `$0090`) nel codice attivo (`games/`, `c64lib/`, `c64kit/`). Tutto l'assembly attivo è compilato e testato per Commodore 64.

---

## 🚀 ROADMAP v2 — EVOLUZIONE DEL FRAMEWORK (Phases 10–14)

### 🎯 PHASE 10 — Stabilizzazione, Merge & CI/CD — **Priorità: Critica**

- **Task 10.1 — Merge controllato del branch `jules-15716038001056046165-7a8d2788`**:
  Eseguire il merge in `main`, quindi **ripristinare le include guard** in `c64lib/hal/c64_hardware.inc` conservando i commenti di documentazione delle macro introdotti dal branch. Allineare `setup.py` (classifiers nuovi + vincoli di dipendenza di `main`).
  *DoD:* `xa` compila `games/invaders` e `games/template` senza errori; `pytest` verde; il file `.inc` può essere incluso N volte senza "Label already defined".
- **Task 10.2 — Fix eager import di pygame**:
  Rendere `c64kit/__init__.py` lazy (import di `InvadersGame` solo su accesso via PEP 562 `__getattr__`) oppure spostare la dipendenza pygame in un extras `pip install c64kit[emulation]`.
  *DoD:* `python3 -c "from c64kit.build.build_system import build_project"` funziona in un ambiente **senza** pygame.
- **Task 10.3 — Test condizionali sui tool esterni**:
  Introdurre `pytest.mark.skipif(shutil.which("xa") is None, ...)` (e analoghi per `c1541`, `cartconv`, `x64sc`) nei test che richiedono tool di sistema.
  *DoD:* `pytest` è verde sia dentro sia fuori il container Docker, con skip espliciti e conteggiati.
- **Task 10.4 — GitHub Actions CI**:
  Workflow `.github/workflows/ci.yml`: build dell'immagine Docker (o install di `xa65` + VICE), compilazione assembly di entrambi i progetti, `pytest`, lint Python (`ruff`), upload degli artifact `.prg`.
  *DoD:* badge CI nel README; PR bloccate se la build fallisce.
- **Task 10.5 — Allineamento versioni e packaging moderno**:
  Introdurre `pyproject.toml`, unificare la versione in un solo punto (`c64kit/__version__.py`), correggere `requires_python` in `plugin.yaml` a `>=3.11`, compilare il CHANGELOG retroattivo per le fasi 1–9.
  *DoD:* `pip install .` funziona da `pyproject.toml`; versione unica e coerente ovunque.

### 🎯 PHASE 11 — Qualità & Performance Assembly — **Priorità: Alta**

- **Task 11.1 — Standard include guard**: verificare/applicare il pattern `#ifndef/#define/#endif` a tutti i `.inc` e moduli `.asm` di `c64lib`; aggiungere un test pytest che include due volte ogni header e compila.
- **Task 11.2 — Raster-time budget**: documentare il costo in cicli delle routine critiche (`sprite_multiplex_sort`, `collision_check_all`, `hud_draw`) e aggiungere misura automatica via VICE monitor nell'harness di test.
- **Task 11.3 — Ottimizzazione sprite multiplexer**: sostituire il Bubble Sort con insertion sort (ottimo per N≤16 quasi-ordinati frame-to-frame) e valutare double buffering dei registri sprite per eliminare flicker ai boundary di raster.
- **Task 11.4 — PAL/NTSC switching**: tabella timing centralizzata e auto-detect (`$02A6`) nel template.

### 🎯 PHASE 12 — Parità c64lib ↔ c64kit: Moduli Mancanti — **Priorità: Media**

- **Task 12.1 — Tilemap & scrolling engine assembly** (parità con `c64kit/video/scroll.py` e `c64kit/game/tilemap.py`): scroller hardware a carattere con double buffering, direzioni 4-way.
- **Task 12.2 — Music player assembly** (parità con `c64kit/audio/music_player.py`): player di pattern/track su IRQ con 3 voci, formato condiviso con `sid_compiler`.
- **Task 12.3 — Compressione risorse**: supporto RLE (e integrazione opzionale Exomizer) nel build system per charset/livelli, con decompressione in `c64lib/core/`.

### 🎯 PHASE 13 — Validazione Framework: Secondo Gioco Demo — **Priorità: Media**

- **Task 13.1 — Nuovo gioco demo** in `games/` di genere diverso da Invaders (es. shooter a scrolling verticale), per validare la genericità di `c64lib` e far emergere gap API.
- **Task 13.2 — Regression testing visuale**: screenshot-diff automatizzato via VICE headless (`vice_harness.py`) su frame di riferimento dei giochi demo.

### 🎯 PHASE 14 — Developer Experience & Release — **Priorità: Bassa**

- **Task 14.1 — Generazione automatica API docs** dai commenti dei moduli assembly → `docs/ASSEMBLY_API.md` sempre allineato.
- **Task 14.2 — Release automation**: GitHub Release con artifact prebuildati (`.prg`, `.d64`, `.crt`) dei giochi demo ad ogni tag semver.
- **Task 14.3 — `new_game.sh` migliorato**: validazione nome, opzione `--with-scrolling` / `--with-music` per scaffold mirati.
