# C64 Game Development Kit (c64kit) & Space Invaders

**c64kit** è un framework e kit di sviluppo software generalizzato progettato per facilitare la creazione, il testing, l'emulazione e la build di giochi per **Commodore 64 (C64)**.

Il progetto si articola su due componenti principali:
1. **c64kit (Python library)**: Un set di moduli Python (`c64kit/`) che simula e si interfaccia con l'architettura hardware del C64 (VIC-II, SID, CIA1/CIA2, CPU e memoria standard) consentendo lo sviluppo guidato dai test e l'automazione della pipeline dei giochi.
2. **c64lib (Assembly modular library)**: Una libreria 6502 in assembly modulare (`c64lib/`) che fornisce un'astrazione pulita dell'hardware C64 (HAL), gestione memoria (ZP allocator), audio engine, video engine, gestori degli input, e framework di gioco (state machine, sprite, collisioni, HUD) per qualsiasi gioco C64.

   I moduli di base di **c64lib/core/** includono:
   - **`memory_manager.asm`**: Gestore della memoria Zero Page (`zp_alloc` e `zp_free`) con tracking bitmap dei blocchi liberi per evitare conflitti d'uso tra diversi sottosistemi.
   - **`vic_engine.asm`**: Inizializzazione video (`vic_init`), selezione del banco di memoria VIC (`vic_set_bank`), copia del set di caratteri custom (`vic_copy_charset`), pulizia schermo/colore (`vic_clear_screen`), sincronizzazione raster (`vic_wait_raster`) e controllo sprite.
   - **`sid_engine.asm`**: Reset SID (`sid_init`), riproduzione note su 3 canali indipendenti (`sid_play_note`), impostazione ADSR e waveform, modulazione del volume principale, e un database integrato di effetti sonori standard (`sid_play_effect`).
   - **`input_system.asm`**: Inizializzazione CIA1 (`input_init`), lettura joystick per porta 1 e 2 (`input_scan_joystick`), scansione tastiera (`input_scan_keyboard`), traduzione caratteri PETSCII (`input_get_key`), e mappatura logica ad alto livello (`input_map_action`).
   - **`irq_scheduler.asm`**: Master IRQ Scheduler a priorità e intervalli (`irq_init`, `irq_add_task`, `irq_remove_task`) che supporta fino a 8 task concorrenti, insieme ad interrupt raster specifici (`irq_set_raster`) e sincronizzazione verticale (`irq_wait_vsync`).

   I moduli del framework di gioco di **c64lib/game/** includono:
   - **`state_machine.asm`**: Macchina a stati finiti (`state_init`, `state_change`, `state_update`, `state_draw`) per gestire l'orchestrazione degli stati di gioco (Boot, Title, Play, GameOver, etc.) tramite una tabella di puntatori a callback.
   - **`sprite_engine.asm`**: Gestore sia di sprite basati su caratteri (blocchi multi-carattere) che di sprite hardware VIC-II (`sprite_draw`, `sprite_clear`, `sprite_animate`, `sprite_move`, `sprite_clip`), ottimizzato per flessibilità e prestazioni.
   - **`collision_system.asm`**: Rilevamento delle collisioni AABB (Axis-Aligned Bounding Box) (`collision_init`, `collision_add`, `collision_remove`, `collision_check_pair`, `collision_check_all`) per un massimo di 24 oggetti attivi, con popolamento automatico di un buffer delle collisioni.
   - **`hud_system.asm`**: Visualizzazione del punteggio (unboxing BCD a 6 cifre), del numero di vite tramite icone e del timer di gioco (`hud_init`, `hud_set_score`, `hud_set_lives`, `hud_set_high_score`, `hud_set_timer`, `hud_draw`, `hud_flash`), con supporto per il posizionamento ad inizio o fine schermo e per effetti di flash colorato.

Il repository include anche **Space Invaders** (`games/invaders/`), un porting di successo dal Commodore PET originariamente ottimizzato e riorganizzato per essere il primo gioco dimostrativo completo del kit.

---

## 🗂️ Struttura del Repository

La struttura del repository è organizzata modularmente per consentire il riutilizzo dei componenti di sviluppo:

```
invaders/                       # Root del repository
├── c64kit/                     # Libreria Python (framework & emulazione)
│   ├── core/                   # Emulazione hardware di base (Memory, CIA, Interrupt)
│   ├── video/                  # Engine video, VIC-II, colori, sprite
│   ├── audio/                  # SID 3 voci, voice allocation, SFX
│   │   └── sfx.py              # Gestione ed effetti sonori
│   ├── input/                  # Joystick (porta 1/2), Matrix keyboard
│   ├── game/                   # State machine, Sprite engine, Collision system, HUD
│   ├── tools/                  # Pipeline conversione asset (PNG->charset/sprite), SFX/music compiler
│   ├── build/                  # Pipeline di build automatizzata per emulatori
│   └── testing/                # Test harness per emulatore VICE
├── c64lib/                     # Libreria assembly 6502 riutilizzabile
│   ├── hal/
│   │   └── c64_hardware.inc    # Costanti hardware C64 complete + macro standard
│   ├── core/                   # Gestione memoria, vic_engine, sid_engine, input, irq_scheduler
│   └── game/                   # Sprite engine assembly, collision system, state machine, HUD
├── games/
│   ├── invaders/               # Space Invaders (gioco completo basato su c64lib)
│   └── template/               # Template minimale per l'avvio rapido di nuovi giochi
├── tests/
│   ├── unit/                   # Test unitari in Python (pytest) per verificare il framework
│   └── integration/            # Test di integrazione tramite emulatore VICE
├── docs/                       # Documentazione delle API Assembly, Python e tutorial
├── Makefile                    # Wrapper per automazione dei comandi legacy
├── setup.py                    # Script di installazione della libreria Python c64kit
└── ROADMAP.md                  # Roadmap dettagliata per lo sviluppo del framework
```

---

## 🎮 Space Invaders (Demo Game)

Il classico gioco *Space Invaders* (stile Taito 1978) è il primo gioco completo sviluppato e ottimizzato per Commodore 64 usando la modularità di `c64lib`.

### Controlli di Gioco

| Comando Tastiera | Comando Joystick (Porta 2) | Azione |
|------------------|---------------------------|--------|
| `A`              | **Sinistra**              | Muovi la base a sinistra |
| `D`              | **Destra**                | Muovi la base a destra |
| `J` oppure `Spazio`| **Pulsante Fuoco**      | Spara il raggio laser |
| `P`              | —                         | Metti in Pausa / Riprendi il gioco |
| `F1`             | —                         | Riavvio Rapido (Quick Restart) da qualsiasi schermata |

---

## 🛠️ Pipeline di Sviluppo & Compilazione

Il progetto automatizza le operazioni sia per la libreria Python che per il codice assembly 6502.

### Prerequisiti
Per programmare e compilare codice C64, assicurarsi di installare l'assemblatore incrociato `xa`:
```bash
sudo apt-get install xa65
```

### Installazione del framework Python `c64kit`
Il toolkit e la suite di test possono essere installati in modalità di sviluppo locale:
```bash
pip install -e .
```

### Comandi Disponibili

- **Compilare il gioco demo (Space Invaders)**:
  ```bash
  make
  ```
  Questo comando assembla i moduli assembly e genera il file eseguibile `invaders64.prg`.

- **Eseguire la suite di test (pytest)**:
  ```bash
  PYTHONPATH=. pytest tests/test_invaders.py
  ```

- **Ripulire gli artefatti di compilazione**:
  ```bash
  make clean
  ```

---

## 🧰 Python Developer Toolkit (Phase 3)

Il framework include ora un insieme completo di strumenti Python (completati nella **Phase 3**) per automatizzare la pipeline di asset, suoni, build e testing:

### 1. Convertitore di Asset (`c64kit.tools.asset_converter`)
Utility CLI per convertire immagini PNG/JPG nei formati grafici nativi del C64 (Hires Charset, Sprite Hardware, o Tilemap) con algoritmo di dithering di Floyd-Steinberg e deduplicazione automatica dei caratteri per ottimizzare lo spazio.

- **Generare un Charset ottimizzato (deduplicato) con anteprima HTML**:
  ```bash
  python -m c64kit.tools.asset_converter --input assets/charset.png --output src/charset.asm --mode charset --preview preview.html
  ```
- **Convertire immagini in Sprite Hardware (24x21 pixel)**:
  ```bash
  python -m c64kit.tools.asset_converter --input assets/sprites.png --output src/sprites.asm --mode sprite
  ```

### 2. Compilatore Audio SID (`c64kit.tools.sid_compiler`)
Traduttore di definizioni SFX ed effetti sonori scritti in formato YAML/JSON in strutture dati assembly 6502 compatibili con il chip audio SID. Supporta rampe di frequenza/cutoff, inviluppi ADSR e note musicali standard (es. `C-4`, `A-4`).

- **Compilare file audio YAML in codice Assembly**:
  ```bash
  python -m c64kit.tools.sid_compiler --input assets/sfx.yaml --output src/sfx_data.asm
  ```

### 3. Build System Incrementale (`c64kit.build.build_system`)
Un gestore di compilazione automatizzato che legge le specifiche da un file di configurazione del progetto `c64project.yaml` ed esegue l'assemblatore incrociato `xa` in modo incrementale (compila solo se le sorgenti o gli asset sono stati modificati dall'ultima build).

- **Eseguire la build del progetto**:
  ```bash
  python -m c64kit.build.build_system --config c64project.yaml
  ```

### 4. Test Harness VICE (`c64kit.testing.vice_harness`)
Libreria per integrare e orchestrare test di integrazione automatici controllando l'emulatore VICE in modalità headless. Supporta il caricamento di programmi `.prg`, la lettura dello stato dei registri SID, la simulazione dell'input e la cattura di screenshot con confronto visivo.

---

## 📝 Documentazione e Roadmap
Per ulteriori dettagli sull'architettura interna, sulle API o sulle fasi future di refactoring, consultare:
- `DOCUMENTATION.md` — Documentazione dettagliata del porting originale PET e del gameplay.
- `ROADMAP.md` — Il piano d'azione completo per guidare l'evoluzione del repository.
