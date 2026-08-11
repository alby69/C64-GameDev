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

## 🔬 ANALISI ARCHITETTURALE ATTUALE

### 1. Stato del Codice Assembly

| File | Righe | Stato | Problema | Note |
|------|-------|-------|----------|------|
| `main.asm` | 40 | ✅ Entry point pulito | BASIC loader hardcoded | Ottimo punto di partenza |
| `memory.inc` | 120 | ✅ Costanti centralizzate | Manca documentazione bit-field | Già modulare |
| `video_init.asm` | 180 | ⚠️ Init monolitico | PAL/NTSC detection + charset + color + SID tutto insieme | Da spezzare |
| `game_loop.asm` | 90 | ⚠️ Loop con logica mista | Contiene anche interrupt vectors e wave logic | Da purificare |
| `video_interrupts.asm` | 50 | ⚠️ Vector setup sparso | 4 versioni di setup IRQ con self-modifying | Da generalizzare |
| `video_raster.asm` | 30 | ✅ Sync semplice | Busy-wait su raster | OK per base |
| `input_movement.asm` | 180 | ⚠️ Input + movimento | Joystick porta 2 + tastiera + movimento player in un file | Da separare |
| `sound_step.asm` | 40 | ✅ Effetto isolato | Solo passo invader | Da estendere |
| `data.asm` | 350 | ⚠️ Dati monolitici | Sprite, stringhe, tabelle, bunker tutto insieme | Da strutturare |
| `game_logic_1.asm` | 450 | ❌ Logica invader | Movimento, collisione, missile nemico, disegno — tutto intrecciato | Da refactoring completo |
| `game_logic_2.asm` | 950 | ❌ Logica game tick | Score, BCD, game over, menu, trainer, high score, bonus — monolite | Da refactoring completo |

**Dipendenze circolari identificate nel codice assembly:**
```
game_loop.asm → game_logic_1.asm (L0800, L0806)
              → game_logic_2.asm (L09FD, L1750)
              → input_movement.asm (L0580)
              → video_interrupts.asm (L0500, L0510, L0520, L0530)
              → sound_step.asm (L0550)

game_logic_1.asm → game_logic_2.asm (L0C00, L0C93, L0D60, L065C)
                 → input_movement.asm (L05B3)
                 → video_raster.asm (L09B0, L09C0)

game_logic_2.asm → game_logic_1.asm (L0600, L0780, L0B06)
                 → video_raster.asm (L09B0)
                 → sound_step.asm (L0550, L16E0, L16EA)
```

**Self-Modifying Code (SMC) identificato:**
| Indirizzo | File | Istruzione | Uso | Rischio |
|-----------|------|------------|-----|---------|
| `L08F3_SELF+1` | `game_logic_1.asm` | `LDA #$00` → delay invader | Cambia velocità ondata | ROM-incompatible, non rientrante |
| `L08D1_SELF+1` | `game_logic_1.asm` | `CPY #$06` → max missili | Cambia numero missili | ROM-incompatible, debug difficile |

**Busy-Wait Delay Loops:**
| Routine | File | Cicli | Problema |
|---------|------|-------|----------|
| `L1680` | `game_logic_2.asm` | ~50000 cicli | Blocca CPU, incompatibile con IRQ avanzati |
| `L16A0` | `game_logic_2.asm` | ~200000 cicli | Blocca CPU, incompatibile con musica background |

### 2. Stato della Libreria Python `c64kit/`

| Modulo | File | Stato | Generico? | Problema |
|--------|------|-------|-----------|----------|
| `core.constants` | 1 file, 40 righe | ✅ Base | Sì | Manca ~60% registri C64 (nessun CIA2, nessun VIC sprite, nessun SID filter) |
| `core.memory` | 1 file, 50 righe | ✅ Buono | Sì | Banking I/O semplificato; manca gestione ROM ($A000-$BFFF, $E000-$FFFF) |
| `core.utils` | 1 file, 60 righe | ✅ Buono | Sì | Conversioni ASCII↔Screen Code↔PETSCII; mappatura caratteri incompleta |
| `video.colors` | 1 file, 30 righe | ✅ Completo | Sì | Palette C64 completa con RGB; manca supporto VIC-II multi-color mode |
| `video.vic` | 1 file, 50 righe | ⚠️ Minimale | Sì | Solo border/bg/charset/raster; manca: sprite regs, scroll, bank switching, interrupt control |
| `video.screen` | 1 file, 80 righe | ⚠️ Specifico | Parzialmente | `draw_sprite()` hardcoded 5×3 char; `draw_bunker()` specifico; manca scroll, split screen |
| `video.charset` | 1 file, 90 righe | ⚠️ Specifico | No | Solo PET graphics $60-$7F; manca: converter da PNG, gestione sprite hardware, charset editor |
| `audio.sid` | 1 file, 60 righe | ⚠️ Minimale | Parzialmente | Solo Voice 1; manca: voice allocation, 3 voci, filter, ring mod, music player |
| `audio.sfx` | 1 file, 70 righe | ❌ Specifico | No | Tabelle FREQ hardcoded per Invaders; nessun sistema generico effetti |
| `input.joystick` | 1 file, 50 righe | ✅ Buono | Sì | Solo porta 2; manca: porta 1, paddle, mouse 1351 |
| `input.keyboard` | 1 file, 80 righe | ⚠️ Limitato | Parzialmente | Mappatura solo 6 tasti; manca: scansione matrice completa, key buffer, debounce avanzato |
| `game.invaders` | 1 file, 280 righe | ❌ Monolite | No | Orchestrazione completa Invaders; pygame rendering inline; logica gioco hardcoded |
| `game.score` | 1 file, 120 righe | ⚠️ Specifico | No | BCD a 4 cifre, indirizzi hardcoded ($033C-$033F), logica extra life a 1500pt |
| `game.sprite_data` | 1 file, 350 righe | ❌ Dati grezzi | No | Tutti i dati Invaders in bytes; nessuna struttura astratta |

**Copertura test (`tests/test_invaders.py`):**
- 13 test functions, ~200 righe
- Copertura: memory, SID, VIC, screen, charset, input, score, game orchestrator
- Manca: test collisioni, test game loop completo, test su emulatore reale, test performance

### 3. Analisi della Documentazione

`DOCUMENTATION.md` (22KB):
- ✅ Eccellente documentazione del codice PET originale
- ✅ Mappa memoria PET dettagliata
- ✅ Spiegazione flusso di gioco
- ✅ Tabella conversione PET→C64
- ❌ Nessuna documentazione del codice C64 attuale
- ❌ Nessuna guida per estendere/modificare
- ❌ Nessuna API reference per `c64kit` Python
- ❌ Nessuna guida per creare nuovi giochi

---

## 🎯 PHASE 1 — Foundation: Estrarre Core Generico Python (COMPLETATA)
**Priority: CRITICAL | Status: 100% COMPLETATA (Sviluppata interamente da Jules nel turn attuale)**

### Task 1.1 — Completare `c64kit.core`: Hardware Completo (COMPLETATO)

**File da modificare/creare:**
- `c64kit/core/constants.py` → espandere
- `c64kit/core/memory.py` → aggiungere ROM banking
- `c64kit/core/cia.py` → NUOVO
- `c64kit/core/interrupts.py` → NUOVO

**Requisiti Jules:**
```
1. Espandi constants.py con TUTTI i registri C64:
   - VIC-II completo: $D000-$D02E (sprite regs, scroll, control)
   - SID completo: $D400-$D41C (3 voci, filter, mod)
   - CIA1 completo: $DC00-$DC0F (timer, serial, interrupt)
   - CIA2 completo: $DD00-$DD0F (timer, serial, NMI)
   - CPU: $01 (banking), $FFFA-$FFFF (vectors)

2. Crea cia.py con classi CIA1 e CIA2 che emulano:
   - Timer A/B con counting e interrupt flag
   - Shift register (per fast serial)
   - TOD clock (Time of Day)
   - Interrupt control (ICR)

3. Estendi memory.py per gestire:
   - ROM overlay: BASIC ($A000-$BFFF), KERNAL ($E000-$FFFF)
   - Bank switching via $01: RAM/ROM/IO modes
   - Cartridge ROM ($8000-$9FFF) opzionale

4. Crea interrupts.py con:
   - VIC-II raster interrupt simulation
   - CIA timer interrupt simulation
   - IRQ/NMI vector handling
   - Interrupt priority queue
```

**Accettazione:**
- Test che verifica: scrittura a $D800 in modalità ROM non modifica RAM
- Test che verifica: timer CIA decrementa correttamente e triggera interrupt
- Test che verifica: sprite registers $D000-$D01F sono accessibili

---

### Task 1.2 — Generalizzare Video Engine (COMPLETATO)

**File da modificare/creare:**
- `c64kit/video/vic.py` → espandere
- `c64kit/video/sprites.py` → NUOVO (sprite hardware VIC-II)
- `c64kit/video/scroll.py` → NUOVO (smooth scroll)

**Requisiti Jules:**
```
1. Espandi VICII class con:
   - Sprite enable/disable ($D015)
   - Sprite positions ($D000-$D01F)
   - Sprite colors ($D027-$D02E)
   - Sprite data pointers ($07F8-$07FF)
   - Scroll registers ($D011, $D016 bit 0-2, 3-7)
   - Multi-color mode ($D016 bit 4)
   - Extended color mode ($D011 bit 6)
   - Raster interrupt ($D012, $D011 bit 7)
   - Sprite-sprite collision ($D01E)
   - Sprite-background collision ($D01F)

2. Crea Sprites class:
   - 8 sprite hardware con stato (x, y, color, frame, enabled, multicolor)
   - Sprite data upload a $2000-$3FFF (bank 1)
   - Collision detection AABB tra sprite
   - Priority (foreground/background)

3. Crea Scroll class:
   - Smooth horizontal scroll ($D016 bit 0-2)
   - Smooth vertical scroll ($D011 bit 0-2)
   - Tile map buffer per scrolling giochi
   - Double buffer support
```

**Accettazione:**
- Test: 8 sprite posizionati, nessun overlap glitch
- Test: scroll orizzontale di 1 pixel senza tearing
- Test: collisione sprite-sprite rilevata correttamente

---

### Task 1.3 — Generalizzare Audio Engine (SID 3 Voci) (COMPLETATO)

**File da modificare/creare:**
- `c64kit/audio/sid.py` → refactoring completo
- `c64kit/audio/voice_allocator.py` → NUOVO
- `c64kit/audio/music_player.py` → NUOVO

**Requisiti Jules:**
```
1. Refactoring SID class:
   - Supporto 3 voci indipendenti (Voice 1/2/3)
   - Ogni voce: freq lo/hi, pulse width, control, ADSR
   - Filter: cutoff, resonance, mode (LP/BP/HP), routing per voce
   - Ring modulation (voice 3 modulates voice 2)
   - Oscillator sync (voice 1 syncs with voice 3)
   - Master volume + filter enable

2. Crea VoiceAllocator:
   - Round-robin o priority-based allocation
   - Stealing: voce più vecchia o più bassa priorità
   - Tracking: quale voce è assegnata a quale effetto

3. Crea MusicPlayer:
   - Sequenza pattern-based (tipo tracker)
   - Supporto per note, instrument, effect
   - Tempo BPM configurabile
   - Loop/pattern jump

4. Mantieni retrocompatibilità con effetti Invaders:
   - SoundEffects class diventa wrapper che usa VoiceAllocator
   - FREQ_TABLE, FREQ_TABLE2, FREQ_EFFECT diventano parametri
```

**Accettazione:**
- Test: 3 note simultanee su 3 canali, frequenze corrette
- Test: filter sweep su voce 1, cutoff da 0 a 2047
- Test: voice stealing quando si richiede 4a voce
- Test: music player suona scale C major a 120 BPM

---

### Task 1.4 — Generalizzare Input System (COMPLETATO)

**File da modificare/creare:**
- `c64kit/input/joystick.py` → espandere
- `c64kit/input/keyboard.py` → espandere
- `c64kit/input/input_manager.py` → NUOVO

**Requisiti Jules:**
```
1. Espandi Joystick:
   - Supporto porta 1 ($DC00) e porta 2 ($DC01)
   - Lettura corretta con CIA1 DDRA/DDRB ($DC02/$DC03)
   - Supporto paddle (potentiometri via CIA timers)
   - Mouse 1351 emulation (analog via paddle + digital button)

2. Espandi Keyboard:
   - Scansione matrice completa 8×8 (righe $DC00, colonne $DC01)
   - Mappatura PETSCII completa (non solo 6 tasti)
   - Key buffer circolare (10 keypress)
   - Debounce software configurabile (3-10 campioni)
   - Supporto key repeat (delay + rate)
   - RESTORE key (NMI trigger)

3. Crea InputManager:
   - Unifica joystick + tastiera in un'unica API
   - Action mapping: configura "MOVE_LEFT" → [joystick_left, key_A, key_left]
   - Stato input frame-per-frame (pressed, held, released)
   - Combo detection (es. Konami code)
```

**Accettazione:**
- Test: pressione 'A' rilevata come PETSCII 0x41
- Test: joystick porta 1 e 2 letti simultaneamente
- Test: action "FIRE" triggerato da space, J, o joystick fire
- Test: debounce elimina bounce meccanico simulato

---

## 🎯 PHASE 2 — Game Framework: Engine Python Riutilizzabile
**Priority: HIGH | Estimated Effort: 5-6 Jules tasks**

### Task 2.1 — Creare Game State Machine

**File da creare:** `c64kit/game/state_machine.py`

**Requisiti Jules:**
```python
class GameStateMachine:
    '''Finite State Machine per stati di gioco C64.'''

    STATES = ['BOOT', 'SPLASH', 'TITLE', 'MENU', 'PLAY', 'PAUSE', 'GAMEOVER', 'HIGHSCORE']

    def __init__(self):
        self.states = {}
        self.current = None
        self.previous = None
        self.transition_table = {}  # valid transitions

    def register_state(self, name: str,
                      on_enter: Callable,
                      on_exit: Callable,
                      on_update: Callable,
                      on_draw: Callable) -> None:
        '''Registra uno stato con callback.'''

    def change_state(self, new_state: str, *args, **kwargs) -> bool:
        '''Transizione di stato con validazione.'''

    def update(self, dt: float) -> None:
        '''Chiama update dello stato corrente.'''

    def draw(self, screen) -> None:
        '''Chiama draw dello stato corrente.'''
```

**Requisiti:**
- Stati predefiniti con lifecycle: enter → update → draw → exit
- Transizioni validate: tabella `from → [valid_to]`
- Passaggio dati tra stati via `context` dict
- Supporto per sub-states (es. PLAY → PAUSE overlay)
- Hook pre/post transizione per effetti (fade, wipe)

**Accettazione:**
- Test: ciclo BOOT→TITLE→PLAY→GAMEOVER→TITLE senza errori
- Test: transizione invalida (PLAY→BOOT) rifiutata
- Test: dati persistono tra TITLE e PLAY (es. high score)

---

### Task 2.2 — Creare Sprite/Tile Engine Generico

**File da creare:**
- `c64kit/game/sprite_engine.py` — char-sprite + hardware sprite
- `c64kit/game/tilemap.py` — tile map per background

**Requisiti Jules:**
```python
class Sprite:
    '''Sprite generico C64 (char-based o hardware).'''
    def __init__(self, x, y, width, height, frames=1,
                 type='char', # o 'hardware'
                 colors=None, collision_box=None):

class SpriteEngine:
    '''Gestisce sprite con ottimizzazione dirty-rectangle.'''
    def __init__(self, memory, screen, max_sprites=32):
    def add(self, sprite: Sprite) -> int:
    def remove(self, sprite_id: int) -> None:
    def move(self, sprite_id, dx, dy) -> None:
    def animate(self, sprite_id, frame) -> None:
    def check_collision(self, id1, id2) -> bool:
    def draw_all(self) -> None:  # dirty rectangle tracking
    def clear_all(self) -> None:

class TileMap:
    '''Tile map per background scrolling.'''
    def __init__(self, width, height, tile_width=1, tile_height=1):
    def set_tile(self, tx, ty, char, color):
    def scroll(self, dx, dy):
    def draw(self, screen, offset_x=0, offset_y=0):
```

**Requisiti:**
- Supporto char-sprite (come Invaders: multi-char blocks)
- Supporto hardware sprite VIC-II (24×21 pixel)
- Dirty rectangle tracking: ridisegna solo aree modificate
- Clipping ai bordi schermo
- Animazione frame-based con timer
- Z-ordering (priorità disegno)
- Tile map con wrap-around opzionale

**Accettazione:**
- Test: 32 char-sprite senza flicker
- Test: 8 hardware sprite con multiplexing simulato
- Test: scroll tile map di 40×25 in < 10ms
- Test: dirty rectangle riduce draw del 70% vs full redraw

---

### Task 2.3 — Creare Collision System Generico

**File da creare:** `c64kit/game/collision_system.py`

**Requisiti Jules:**
```python
class CollisionSystem:
    '''Sistema collisioni AABB + spatial hash.'''

    COLLISION_TYPES = ['PLAYER', 'ENEMY', 'BULLET', 'BONUS',
                       'BUNKER', 'WALL', 'ITEM', 'TRIGGER']

    def __init__(self, cell_size=8, grid_width=40, grid_height=25):
    def add_object(self, obj_id, x, y, w, h, type, mask=None):
    def remove_object(self, obj_id):
    def update_position(self, obj_id, x, y):
    def check_all(self) -> List[Collision]:
    def check_pair(self, id1, id2) -> Optional[Collision]:
    def check_point(self, x, y, type_mask) -> List[int]:
    def set_callback(self, type1, type2, callback):
```

**Requisiti:**
- Spatial grid 8×8 celle (configurabile)
- AABB (Axis-Aligned Bounding Box) con opzione pixel-precision
- Collision layers/mask: oggetti possono ignorare certi tipi
- Callback system: `on_collision(type1, type2, obj1, obj2)`
- Bullet-through-paper prevention (swept collision)
- Performance: 50 oggetti, check < 1ms

**Accettazione:**
- Test: 20 invader + 5 bunker + 3 bullet, nessun missed collision
- Test: bullet che attraversa invader in 1 frame rilevato (swept)
- Test: performance < 1ms per frame con 50 oggetti

---

### Task 2.4 — Creare HUD/Score System Generico

**File da creare:** `c64kit/game/hud_system.py`

**Requisiti Jules:**
```python
class HUDSystem:
    '''Head-Up Display generico per giochi C64.'''

    def __init__(self, screen, position='top', colors=None):
    def add_element(self, name, type, x, y, format_str,
                   color=Colors.WHITE, update_fn=None):
    def set_score(self, player, value):
    def set_lives(self, player, count, icon_char=0x6C):
    def set_high_score(self, value):
    def set_timer(self, seconds):
    def set_text(self, name, text):
    def draw(self):
    def flash(self, name, duration_ms, color=Colors.RED):

class ScoreManager:
    '''Gestione punteggio con BCD e persistenza.'''
    def __init__(self, memory, digits=4, base_addr=0x033C):
    def add(self, points: int) -> None:
    def get(self) -> int:
    def set(self, value: int) -> None:
    def check_extra_life(self, threshold: int) -> bool:
    def save_high_score(self, filename='highscore.dat'):
    def load_high_score(self, filename='highscore.dat'):
```

**Requisiti:**
- Score BCD con cifre configurabili (3-6)
- Multi-player: 2 giocatori con score separati
- High score persistenza su file
- Formattazione: leading zeros, separatore migliaia, hex display opzionale
- Timer countdown/up con BCD
- Elementi HUD posizionabili: top, bottom, split-screen
- Flash effect per warning (low life, time up)

**Accettazione:**
- Test: score 0→999999 senza glitch BCD
- Test: high score salvato e ricaricato correttamente
- Test: 2 player, switch score display

---

### Task 2.5 — Creare Level/Entity System

**File da creare:**
- `c64kit/game/level_manager.py`
- `c64kit/game/entity_manager.py`

**Requisiti Jules:**
```python
@dataclass
class LevelConfig:
    name: str
    enemy_layout: List[Tuple[int, int, int]]  # (x, y, type)
    player_start: Tuple[int, int]
    bunker_positions: List[Tuple[int, int]]
    bonus_frequency: int
    speed_curve: List[int]  # delay per ondata
    palette: List[int]  # colori per tipo

class LevelManager:
    def load_level(self, config: LevelConfig) -> None:
    def next_wave(self) -> LevelConfig:
    def get_current(self) -> LevelConfig:
    def serialize(self) -> bytes:  # per export assembly
    def deserialize(self, data: bytes) -> LevelConfig:

class EntityManager:
    def spawn(self, entity_type, x, y, **props) -> int:
    def destroy(self, entity_id) -> None:
    def get_all(self, entity_type) -> List[Entity]:
    def update_all(self, dt) -> None:
    def draw_all(self) -> None:
```

**Accettazione:**
- Test: level con 55 invader, 4 bunker, 1 player generato correttamente
- Test: export level in formato `.byte` assembly compilabile
- Test: entity spawn/destroy senza memory leak (verifica con contatore)

---

## 🎯 PHASE 3 — Python Toolkit: Build, Asset, Test (COMPLETATA)
**Priority: HIGH | Status: 100% COMPLETATA (Sviluppata interamente da Jules nel turn attuale)**

### Task 3.1 — Asset Converter Pipeline

**File da creare:** `c64kit/tools/asset_converter.py`

**Requisiti Jules:**
```python
# CLI
python -m c64kit.tools.asset_converter \
  --input assets/sprites.png \
  --output src/sprites.asm \
  --format asm \
  --mode charset  # charset | sprite | tilemap | music

# Features:
# - Palette C64 fixed (16 colori)
# - Dithering Floyd-Steinberg per immagini > 16 colori
# - Ottimizzazione: rimuovi char duplicati, riordina per frequenza
# - Preview HTML con colori C64 reali
# - Multi-frame per animazioni
# - Export: asm (.byte), bin (raw), c (header)
# - Sprite hardware: 24×21 pixel, 1 color + transparent
# - Charset: 8×8 pixel, max 256 char, ottimizzazione deduplica
```

**Accettazione:**
- Test: conversione logo Invaders con < 5% errore percettivo
- Test: charset da 128 tile unici, nessun duplicato
- Test: preview HTML matcha risultato su VICE

---

### Task 3.2 — SID Music/SFX Compiler

**File da creare:** `c64kit/tools/sid_compiler.py`

**Requisiti Jules:**
```yaml
# Input YAML/JSON
sfx:
  shoot:
    channel: any
    waveform: [noise, sawtooth]
    attack: 0; decay: 8; sustain: 0; release: 0
    freq_start: 8000; freq_end: 2000
    duration_ms: 150
  explosion:
    channel: any
    waveform: noise
    attack: 0; decay: 12; sustain: 4; release: 8
    filter: {mode: lowpass, cutoff_start: 800, cutoff_end: 100, resonance: 8}

music:
  bpm: 120
  patterns:
    - [C-3, 1, 0x41, ..., ...]  # note, instrument, effect
```

**Accettazione:**
- Test: export effetti Invaders identici all'originale
- Test: A/B comparison con file originale su VICE

---

### Task 3.3 — Build System Python

**File da creare:** `c64kit/build/build_system.py`

**Requisiti Jules:**
```yaml
# c64project.yaml
project:
  name: "Space Invaders C64"
  version: "1.2.0"
  target: c64

build:
  assembler: xa
  flags: [-XMASM, -W, -v]
  source_dirs: [src, c64lib]
  main: src/main.asm
  output: build/invaders64.prg

assets:
  charset: assets/charset.png
  sprites: assets/sprites.png
  sfx: assets/sfx.yaml

testing:
  emulator: x64sc
  timeout_cycles: 5000000
  screenshot_compare: tests/ref/

packaging:
  d64: true
  crt: false
```

**Accettazione:**
- Build completo < 5 secondi
- Incremental build: ricompila solo file modificati
- Test headless passa se gioco arriva a schermata titolo

---

### Task 3.4 — Emulator Test Harness

**File da creare:** `c64kit/testing/vice_harness.py`

**Requisiti Jules:**
```python
class VICEHarness:
    def load_prg(self, path, address=None)
    def run_until(self, condition: Callable, timeout_ms=5000)
    def read_memory(self, addr, length=1)
    def press_key(self, key)
    def get_screenshot(self) -> Image
    def compare_screenshot(self, reference_path, threshold=0.01)
    def get_sid_state(self) -> SIDState
```

**Accettazione:**
- Test: schermata titolo appare entro 2 secondi
- Test: pressione 'F1' causa restart
- Test: punteggio incrementa dopo collisione

---

## 🎯 PHASE 4 — Refactoring Assembly: `c64lib/` (COMPLETATA)
**Priority: HIGH | Status: 100% COMPLETATA (Sviluppata interamente da Jules nel turn attuale)**

### Task 4.1 — Estrarre HAL (Hardware Abstraction Layer) (COMPLETATO)

**File da creare:** `c64lib/hal/c64_hardware.inc`

**Requisiti Jules:**
```asm
; ============================================================================
; c64lib/hal/c64_hardware.inc
; ============================================================================
; Costanti hardware C64 complete + macro

; VIC-II completo
VIC_SPR0_X  = $D000
VIC_SPR0_Y  = $D001
...
VIC_SPR7_X  = $D00E
VIC_SPR7_Y  = $D00F
VIC_MSBG_X  = $D010
VIC_CTRL1   = $D011
VIC_RASTER  = $D012
VIC_LPX     = $D013
VIC_LPY     = $D014
VIC_SPR_EN  = $D015
VIC_CTRL2   = $D016
VIC_SPR_YEX = $D017
VIC_MEM     = $D018
VIC_IRR     = $D019
VIC_IRQMASK = $D01A
VIC_SPR_DP  = $D01E
VIC_SPR_DB  = $D01F
VIC_BORDER  = $D020
VIC_BG0     = $D021
...

; SID completo
SID_V1_FREQ_LO = $D400
...
SID_FILTER_CUTOFF = $D415
SID_FILTER_RES    = $D416
SID_FILTER_MODE   = $D417
SID_VOLUME        = $D418

; CIA completo
CIA1_PRA = $DC00
...
CIA1_ICR = $DC0D
CIA2_PRA = $DD00
...
CIA2_ICR = $DD0D

; Macro
.macro SAFE_SEI
    PHP
    SEI
.endm

.macro SAFE_CLI
    PLP
.endm

.macro SET_VIC_BANK bank
    LDA $DD00
    AND #$FC
    ORA #(3-bank)
    STA $DD00
.endm
```

**Accettazione:**
- `xa -c c64lib/hal/c64_hardware.inc` compila senza errori
- Nessun `.define` duplicato con `memory.inc`

---

### Task 4.2 — Estrarre Memory Manager (COMPLETATO)

**File da creare:** `c64lib/core/memory_manager.asm`

**Requisiti Jules:**
```asm
; Zero page allocation tracker
ZP_ALLOC_TABLE = $0200  ; 32 slot da 1 byte (bitmap)
ZP_USER_START  = $10    ; $10-$CF allocabile
ZP_USER_END    = $CF

; Routine
zp_alloc:      ; Input: A = bytes needed (2,4,6,8)
               ; Output: X = start index, C=1 ok, C=0 fail
zp_free:       ; Input: X = start index

; Memory map configurabile
MEMORY_SCREEN    = $0400
MEMORY_COLOR     = $D800
MEMORY_CHARSET   = $3800
MEMORY_SPRITE    = $2000
```

**Accettazione:**
- Test Python che simula allocazione/deallocazione ZP
- Nessun conflitto con indirizzi KERNAL

---

### Task 4.3 — Estrarre Video Core (COMPLETATO)

**File da creare:** `c64lib/core/vic_engine.asm`

**Requisiti Jules:**
```asm
; Estrai da video_init.asm:
; - START (charset copy) → vic_copy_charset
; - L16C0 (clear screen) → vic_clear_screen
; - L09B0/L09C0 (raster sync) → vic_wait_raster
; - Color RAM init → vic_init_colors

vic_init:            ; Input: A=screen bank, X=charset bank, Y=colors
vic_set_bank:        ; Input: A=bank (0-3)
vic_copy_charset:    ; Input: ZFB=src, ZFC=dst
vic_clear_screen:    ; Input: A=char, Y=color
vic_wait_raster:     ; Input: A=line
vic_set_colors:      ; Input: A=border, X=bg, Y=aux
vic_enable_sprites:  ; Input: A=mask ($D015)
vic_set_sprite_pos:  ; Input: X=sprite_id, Y=x, A=y
```

**Accettazione:**
- Clear screen < 5000 cicli (vs ~10000 attuali)
- Test: 8 sprite posizionati senza glitch

---

### Task 4.4 — Estrarre Audio Engine (COMPLETATO)

**File da creare:** `c64lib/core/sid_engine.asm`

**Requisiti Jules:**
```asm
; Estrai da sound_step.asm, game_logic_2.asm (L16E0, L16EA, L1652)
; Generalizza per 3 canali

sid_init:                ; Resetta tutti i registri
sid_play_note:           ; Input: A=channel(0-2), X=freq_lo, Y=freq_hi
sid_set_waveform:        ; Input: A=channel, X=waveform
sid_set_adsr:            ; Input: A=channel, X=attack|decay, Y=sustain|release
sid_play_effect:         ; Input: A=effect_id
sid_stop_channel:        ; Input: A=channel
sid_set_filter:          ; Input: A=mode, X=cutoff_lo, Y=cutoff_hi
sid_set_volume:          ; Input: A=vol(0-15)

; Tabella effetti strutturata
SFX_TABLE:
    .word sfx_shoot, sfx_explosion, sfx_step, sfx_bonus, sfx_gameover

sfx_shoot:
    .byte $00, $00    ; freq_lo, freq_hi
    .byte $80          ; waveform (noise)
    .byte $08, $00     ; AD, SR
    .byte 10           ; duration frames
```

**Accettazione:**
- Test: scale su 3 canali
- Effetto explosion con filter sweep
- Nessun click/pop

---

### Task 4.5 — Estrarre Input System (COMPLETATO)

**File da creare:** `c64lib/core/input_system.asm`

**Requisiti Jules:**
```asm
; Estrai da input_movement.asm (L0580)
; Generalizza per entrambe le porte

input_init:              ; Configura CIA1
input_scan_joystick:     ; Input: A=port(1-2), Output: A=bits
input_scan_keyboard:     ; Output: A=matrix code, X=row, Y=col
input_get_key:           ; Output: A=PETSCII, 0=none
input_map_action:        ; Input: A=action_id, Output: A=pressed?

; Struttura stato
INPUT_STATE:
    .byte $00  ; joystick_port1
    .byte $00  ; joystick_port2
    .byte $00  ; keyboard_matrix_code
    .byte $00  ; debounce_counter
    .byte $00  ; action_flags
```

**Accettazione:**
- Test: stato di tutti gli input mostrato su schermo
- Nessun ghosting

---

### Task 4.6 — Estrarre IRQ Scheduler (COMPLETATO)

**File da creare:** `c64lib/core/irq_scheduler.asm`

**Requisiti Jules:**
```asm
; Sostituisce delay loop busy-wait con timer IRQ
; Estrai da video_interrupts.asm (L0500, L0510, L0520, L0530)
; Estrai da game_logic_2.asm (L09FD, L1750)

irq_init:                ; Installa handler custom
irq_add_task:            ; Input: A=priority, X=interval, Y=callback_lo, Z=callback_hi
irq_remove_task:         ; Input: A=task_id
irq_set_raster:          ; Input: A=line, Y=callback_lo, Z=callback_hi
irq_wait_vsync:          ; Blocca fino a raster $100 (o SYNC_LINE_VAL)

; Task queue in memoria pagina 2 ($0240-$02FF)
; 8 task: .byte active, priority, interval, counter, .word callback
```

**Accettazione:**
- Test: 4 task a 50Hz, 25Hz, 10Hz, 5Hz
- Nessun jitter > 1 raster line
- Stack pointer stabile dopo 1000 interrupt

---

## 🎯 PHASE 5 — Game Framework Assembly
**Priority: MEDIUM | Estimated Effort: 4-5 Jules tasks**

### Task 5.1 — Sprite/Tile Engine Assembly

**File da creare:** `c64lib/game/sprite_engine.asm`

**Requisiti Jules:**
```asm
; Supporto char-sprite (come Invaders: 5×3) + hardware sprite

SPRITE_DEF:
    .byte x, y          ; Posizione schermo
    .byte width, height ; Dimensioni in char
    .byte frame         ; Frame corrente
    .byte flags         ; Bit 7=active, 6=hw_sprite, 5=multicolor
    .word data_ptr      ; Puntatore a dati sprite

sprite_draw:             ; Input: ZFB=puntatore a SPRITE_DEF
sprite_clear:            ; Ripristina background
sprite_animate:          ; Input: A=frame_count
sprite_move:             ; Input: A=dx, X=dy
sprite_clip:             ; Clipping ai bordi
```

**Accettazione:**
- Demo: 8 sprite che si muovono indipendentemente
- Test clipping: sprite esce da sinistra, rientra da destra

---

### Task 5.2 — Collision System Assembly

**File da creare:** `c64lib/game/collision_system.asm`

**Requisiti Jules:**
```asm
; Estrai da game_logic_1.asm (L0683-L06C9, L0D00-L0D58)
; AABB generico + spatial grid

collision_init:          ; Input: A=grid_size
collision_add:           ; Input: A=id, X=x, Y=y, ZFB=w, ZFC=h, ZFD=type
collision_remove:        ; Input: A=id
collision_check_all:     ; Output: lista collisioni in buffer
collision_check_pair:    ; Input: A=id1, X=id2

; Tipi: PLAYER=0, ENEMY=1, BULLET=2, BONUS=3, BUNKER=4, WALL=5
; Callback table: .word handler_00, handler_01, ... (16 combinazioni)
```

**Accettazione:**
- Benchmark: 20 oggetti, check < 1 frame PAL (20ms)
- Test: bullet vs bunker con pixel-precision

---

### Task 5.3 — State Machine Assembly

**File da creare:** `c64lib/game/state_machine.asm`

**Requisiti Jules:**
```asm
; Stati predefiniti
STATE_BOOT    = 0
STATE_TITLE   = 1
STATE_MENU    = 2
STATE_PLAY    = 3
STATE_PAUSE   = 4
STATE_GAMEOVER= 5
STATE_HIGH    = 6

; Tabella stati (7 stati × 4 word = 56 byte)
STATE_TABLE:
    .word state_boot_enter, state_boot_exit, state_boot_update, state_boot_draw
    .word state_title_enter, ...

state_init:              ; Input: ZFB=puntatore a STATE_TABLE
state_change:            ; Input: A=new_state
state_update:            ; Chiama update stato corrente
state_draw:              ; Chiama draw stato corrente
```

**Accettazione:**
- Demo: ciclo tra 4 stati con transizioni visibili
- Nessun memory leak tra cambi stato

---

### Task 5.4 — HUD/Score System Assembly

**File da creare:** `c64lib/game/hud_system.asm`

**Requisiti Jules:**
```asm
; Estrai da game_logic_2.asm (L0A60, L0C78, L0C93, L17A0)
; Generalizza posizione, cifre, colori

hud_init:                ; Input: A=position(0=top,1=bottom), X=color
hud_set_score:           ; Input: A=player(0-1), ZFB=score_lo, ZFC=score_hi (BCD)
hud_set_lives:           ; Input: A=count, X=icon_char
hud_set_high_score:      ; Input: ZFB=lo, ZFC=hi
hud_set_timer:           ; Input: A=seconds
hud_draw:                ; Renderizza tutto HUD
hud_flash:               ; Input: A=element_id, X=duration, Y=color
```

**Accettazione:**
- Test: score 0→999999 BCD senza glitch
- Test: 2 player HUD su schermo diviso

---

## 🎯 PHASE 6 — Refactoring Space Invaders
**Priority: MEDIUM | Estimated Effort: 3-4 Jules tasks**

### Task 6.1 — Portare Invaders su c64lib

**File da creare/modificare:** `games/invaders/src/main.asm`

**Requisiti Jules:**
```
- Crea directory games/invaders/ con struttura:
  games/invaders/
  ├── src/
  │   ├── main.asm          # Entry point, state machine
  │   ├── game_states/
  │   │   ├── state_boot.asm
  │   │   ├── state_title.asm
  │   │   ├── state_menu.asm
  │   │   ├── state_play.asm
  │   │   ├── state_pause.asm
  │   │   └── state_gameover.asm
  │   ├── entities/
  │   │   ├── player.asm
  │   │   ├── invader.asm
  │   │   ├── missile.asm
  │   │   ├── bunker.asm
  │   │   └── bonus.asm
  │   └── data/
  │       ├── sprite_data.asm
  │       ├── sfx_data.asm
  │       └── level_data.asm
  ├── assets/
  │   ├── charset.png
  │   └── sfx.yaml
  └── c64project.yaml

- main.asm deve essere < 100 linee:
  #include "c64lib/hal/c64_hardware.inc"
  #include "c64lib/core/memory_manager.asm"
  #include "c64lib/core/vic_engine.asm"
  #include "c64lib/core/sid_engine.asm"
  #include "c64lib/core/input_system.asm"
  #include "c64lib/core/irq_scheduler.asm"
  #include "c64lib/game/state_machine.asm"
  #include "c64lib/game/sprite_engine.asm"
  #include "c64lib/game/collision_system.asm"
  #include "c64lib/game/hud_system.asm"

  .include "game_states/state_boot.asm"
  .include "game_states/state_title.asm"
  ...

  START:
      jsr vic_init
      jsr sid_init
      jsr input_init
      jsr irq_init
      jsr state_init
      lda #STATE_BOOT
      jsr state_change

  MAIN_LOOP:
      jsr state_update
      jsr state_draw
      jsr irq_wait_vsync
      jmp MAIN_LOOP
```

**Accettazione:**
- `make` in `games/invaders/` produce `invaders64.prg` funzionalmente identico
- `main.asm` < 100 linee effettive
- Nessun codice duplicato tra stati

---

### Task 6.2 — Rimuovere Self-Modifying Code

**File da modificare:** `games/invaders/src/entities/invader.asm`

**Requisiti Jules:**
```
- Trova tutte le occorrenze SMC:
  * L08F3_SELF+1 (delay invader) → variabile invader_speed_delay
  * L08D1_SELF+1 (max missili) → variabile max_missiles
- Sostituisci LDA #imm con LDA variable (1 ciclo in più)
- Verifica performance entro 105% del codice SMC
- Aggiungi commento: ; SMC removed for ROM compatibility
```

**Accettazione:**
- Codice eseguibile da ROM
- Test: 10 ondate, nessun crash

---

### Task 6.3 — Generalizzare Level Data

**File da creare:** `games/invaders/src/data/level_data.asm`

**Requisiti Jules:**
```asm
LEVEL_STRUCT:
  .byte num_invaders      ; 55 max
  .byte num_rows           ; 5 max
  .byte num_cols           ; 11 max
  .byte invader_types      ; bitmask tipo per riga
  .byte initial_speed      ; delay frame
  .byte speed_increment    ; riduzione delay per ondata
  .byte bonus_frequency    ; 1/N frame
  .byte bunker_count       ; 0-4
  .word score_per_invader  ; tabella punteggi
  .word palette_ptr        ; colori per tipo

LEVEL_1:
  .byte 55, 5, 11
  .byte $03, $03, $03, $02, $02
  .byte 8, 1, 256, 4
  .word SCORE_TABLE_STD, PALETTE_CLASSIC

LEVEL_2:
  .byte 55, 5, 11
  .byte $03, $03, $02, $02, $01
  .byte 6, 1, 200, 3
  .word SCORE_TABLE_HARD, PALETTE_GREEN
```

**Accettazione:**
- Aggiunta LEVEL_2 non richiede modifiche codice gioco
- Test: LEVEL_2 ha invader più veloci e meno bunker

---

## 🎯 PHASE 7 — Developer Experience & Documentazione
**Priority: MEDIUM | Estimated Effort: 2-3 Jules tasks**

### Task 7.1 — Template Nuovo Gioco

**File da creare:** `games/template/`

**Requisiti Jules:**
```
- Template minimale con:
  * Schermata titolo con testo scorrevole
  * 1 sprite controllabile con joystick
  * 1 nemico che rimbalza ai bordi
  * Collisione base
  * Score e vite
  * Game over e restart
- Documentazione: 10 passi per creare nuovo gioco
- Script: ./new_game.sh "MyGame" → crea games/mygame/ da template
```

---

### Task 7.2 — Documentazione API

**File da creare:** `docs/ASSEMBLY_API.md`, `docs/PYTHON_API.md`

**Requisiti Jules:**
```markdown
# C64Lib Assembly API

## vic_init
```asm
; Input: A = screen bank, X = charset bank, Y = colors
; Clobber: A, X, Y
jsr vic_init
```
## sid_play_effect
```asm
; Input: A = effect_id, X = priority
; Output: C = 1 se accodato, 0 se scartato
jsr sid_play_effect
```
```
- Genera automaticamente da commenti assembly
- Tabella cicli CPU e byte usati per ogni routine
```

---

### Task 7.3 — Tutorial "Primo Gioco in 30 Minuti"

**File da creare:** `docs/TUTORIAL_30MIN.md`

**Contenuto:**
1. Setup ambiente (Python, xa, VICE)
2. `python -m c64devkit new-game --name Pong`
3. Modifica paddle e palla
4. Aggiungi suono
5. Build e test su VICE

---

## 🎯 PHASE 8 — Ottimizzazioni Avanzate
**Priority: LOW | Estimated Effort: 2-3 Jules tasks**

### Task 8.1 — Sprite Hardware VIC-II
- Migrare da char-sprite a sprite hardware per giochi futuri
- Multiplexing 8+ sprite via raster split

### Task 8.2 — Scroll Orizzontale/Verticale
- Supporto smooth scroll VIC-II ($D011, $D016)
- Tile map con buffer doppio

### Task 8.3 — Cartridge Support (CRT/EasyFlash)
- Build target per cartridge 8KB/16KB/ULTIMAX
- Bank switching per giochi > 64KB

---

## 📊 METRICHE DI SUCCESSO

| Metrica | Target | Come Misurare |
|---------|--------|---------------|
| **Modularità Assembly** | main.asm < 100 LOC | `wc -l` |
| **Modularità Python** | `c64kit/game/invaders.py` < 50% LOC vs totale | `cloc` |
| **Riutilizzo** | > 80% codice in `c64lib/` + `c64kit/core/` | `cloc` |
| **Build Time** | < 5s full, < 1s incremental | `time python -m c64kit.build` |
| **Test Coverage** | > 80% routine testate | pytest coverage |
| **Performance** | < 105% cicli vs originale | Confronto su VICE monitor |
| **Documentazione** | 100% API documentate | `docs/` completeness |
| **Nuovo Gioco** | Template funzionante in < 30 min | Test utente |

---

## 🗂️ STRUTTURA REPOSITORY TARGET

```
invaders/                       # Repository root
├── c64kit/                     # Libreria Python (framework)
│   ├── __init__.py
│   ├── core/                   # Hardware emulation
│   │   ├── constants.py        # Registri C64 completi
│   │   ├── memory.py           # 64KB memory model + banking
│   │   ├── cia.py              # CIA1/CIA2 emulation
│   │   ├── interrupts.py       # IRQ/NMI simulation
│   │   └── utils.py            # Conversioni ASCII/PETSCII
│   ├── video/                  # Video engine
│   │   ├── colors.py           # Palette C64
│   │   ├── vic.py              # VIC-II wrapper completo
│   │   ├── screen.py           # Screen RAM operations
│   │   ├── charset.py          # Charset management
│   │   ├── sprites.py          # Hardware sprite engine
│   │   └── scroll.py           # Smooth scroll + tilemap
│   ├── audio/                  # Audio engine
│   │   ├── sid.py              # SID 3 voci + filter
│   │   ├── voice_allocator.py  # Voice allocation
│   │   ├── music_player.py     # Pattern-based music
│   │   └── sfx.py              # Sound effects (retrocompatibile)
│   ├── input/                  # Input engine
│   │   ├── joystick.py         # Joystick porta 1/2
│   │   ├── keyboard.py         # Keyboard matrix completa
│   │   └── input_manager.py    # Unified input + action mapping
│   ├── game/                   # Game framework
│   │   ├── state_machine.py    # FSM per stati gioco
│   │   ├── sprite_engine.py    # Char-sprite + HW sprite
│   │   ├── collision_system.py # AABB + spatial grid
│   │   ├── hud_system.py       # Score, vite, high score
│   │   ├── level_manager.py    # Level config + serialization
│   │   └── entity_manager.py   # Entity spawn/destroy/update
│   ├── tools/                  # Toolkit
│   │   ├── asset_converter.py  # PNG→charset/sprite/tilemap
│   │   ├── sid_compiler.py     # SFX YAML→assembly
│   │   └── memviz.py           # Visualizzatore memoria
│   ├── build/                  # Build system
│   │   └── build_system.py     # Build automation + packaging
│   └── testing/                # Testing
│       └── vice_harness.py     # Test headless VICE
├── c64lib/                     # Libreria assembly 6502
│   ├── hal/
│   │   └── c64_hardware.inc    # Costanti hardware + macro
│   ├── core/
│   │   ├── memory_manager.asm  # ZP allocator, memory map
│   │   ├── vic_engine.asm      # Video, charset, screen
│   │   ├── sid_engine.asm      # Audio 3 canali
│   │   ├── input_system.asm    # Joystick + tastiera
│   │   └── irq_scheduler.asm   # Task system IRQ-based
│   └── game/
│       ├── state_machine.asm   # FSM per stati gioco
│       ├── sprite_engine.asm   # Char-sprite + HW sprite
│       ├── collision_system.asm # AABB + spatial grid
│       └── hud_system.asm      # Score, vite, high score
├── games/
│   ├── invaders/               # Space Invaders (refactored)
│   │   ├── src/
│   │   │   ├── main.asm
│   │   │   ├── game_states/
│   │   │   ├── entities/
│   │   │   └── data/
│   │   ├── assets/
│   │   └── c64project.yaml
│   └── template/               # Template nuovo gioco
│       └── ...
├── tests/
│   ├── unit/                   # Test Python (pytest)
│   └── integration/            # Test VICE + screenshot ref
├── docs/
│   ├── ASSEMBLY_API.md
│   ├── PYTHON_API.md
│   ├── TUTORIAL_30MIN.md
│   └── MEMORY_MAP.md
├── Makefile                    # Legacy (wrapper su Python build)
├── c64project.yaml             # Config globale
├── setup.py                    # Installazione c64kit
└── README.md                   # Documentazione aggiornata
```

---

## ⚠️ NOTE PER JAPAN / JULES

### Pattern di Codice Python da Rispettare
1. **Type hints obbligatori** su tutte le funzioni pubbliche
2. **Docstring Google-style**:
   ```python
   def function(arg: int) -> bool:
       """Short description.

       Args:
           arg: Description.

       Returns:
           Description.
       """
   ```
3. **Naming:** `snake_case` per funzioni/variabili, `PascalCase` per classi, `UPPER_CASE` per costanti
4. **Ogni modulo** deve avere `__all__` esplicito
5. **Test:** ogni funzione pubblica deve avere test pytest

### Pattern di Codice Assembly da Rispettare
1. **Header standard** per ogni file:
   ```asm
   ; ============================================================================
   ; MODULE: nome_modulo
   ; PURPOSE: descrizione breve
   ; DEPENDS: lista file .inc richiesti
   ; CLOBBER: A, X, Y (specificare quali registri modifica)
   ; ============================================================================
   ```
2. **Naming:**
   - Routine pubbliche: `modulo_azione_soggetto` (es. `vic_clear_screen`)
   - Routine private: `_modulo_nome` (prefisso underscore)
   - Costanti: `MODULO_NOME_COSTANTE` (uppercase)
   - Variabili ZP: `zModuloNome` (prefisso z, camelCase)
   - Variabili memoria: `mModuloNome` (prefisso m)
3. **Self-Modifying Code:** VIETATO in `c64lib/`. Permesso solo in `games/` con commento `; SMC: reason = ...`
4. **IRQ Safety:**
   - Salvare A, X, Y su stack
   - Non usare routine KERNAL (tranne `KERNAL_IRQ` finale)
   - Durata < 2000 cicli (≈ 2.5ms PAL)

### Test Strategy
- Ogni task Jules deve includere test minimale
- Usare `c64kit.testing.vice_harness` per verifica automatica
- Screenshot reference in `tests/ref/`
- Confronto con build originale: bit-identical su memoria video dopo N frame

---

## 🚀 PROSSIMA AZIONE IMMEDIATA

**Task 0 — Bootstrap Repository Structure**

Jules dovrebbe iniziare con:
1. Creare directory structure target (`c64lib/`, `games/`, `docs/`)
2. Inizializzare `setup.py` per `c64kit` con dipendenze (`pygame`, `pyyaml`, `Pillow`)
3. Estrarre `c64_hardware.inc` da `memory.inc` + espandere con registri mancanti
4. Commit iniziale: `chore: bootstrap c64kit modular architecture`
