# C64 Game Development Kit (c64kit) & Space Invaders

**c64kit** è un framework e kit di sviluppo software generalizzato progettato per facilitare la creazione, il testing, l'emulazione e la build di giochi per **Commodore 64 (C64)**.

Il progetto si articola su due componenti principali:
1. **c64kit (Python library)**: Un set di moduli Python (`c64kit/`) che simula e si interfaccia con l'architettura hardware del C64 (VIC-II, SID, CIA1/CIA2, CPU e memoria standard) consentendo lo sviluppo guidato dai test e l'automazione della pipeline dei giochi.
2. **c64lib (Assembly modular library)**: Una libreria 6502 in assembly modulare (`c64lib/`) che fornisce un'astrazione pulita dell'hardware C64 (HAL), gestione memoria (ZP allocator), audio engine, video engine, gestori degli input, e framework di gioco (state machine, sprite, collisioni, HUD) per qualsiasi gioco C64.

> **Nota:** Tutto il codice assembly nel progetto è **esclusivamente per Commodore 64**. Il codice storico per Commodore PET è archiviato (non compilato) in `source/pet/`.

   I moduli di base di **c64lib/core/** includono:
   - **`memory_manager.asm`**: Gestore della memoria Zero Page (`zp_alloc` e `zp_free`) con tracking bitmap dei blocchi liberi per evitare conflitti d'uso tra diversi sottosistemi.
   - **`vic_engine.asm`**: Inizializzazione video (`vic_init`), selezione del banco di memoria VIC (`vic_set_bank`), copia del set di caratteri custom (`vic_copy_charset`), pulizia schermo/colore (`vic_clear_screen`), sincronizzazione raster (`vic_wait_raster`) e controllo sprite.
   - **`sid_engine.asm`**: Reset SID (`sid_init`), riproduzione note su 3 canali indipendenti (`sid_play_note`), impostazione ADSR e waveform, modulazione del volume principale, e un database integrato di effetti sonori standard (`sid_play_effect`).
   - **`input_system.asm`**: Inizializzazione CIA1 (`input_init`), lettura joystick per porta 1 e 2 (`input_scan_joystick`), scansione tastiera (`input_scan_keyboard`), traduzione caratteri PETSCII (`input_get_key`), e mappatura logica ad alto livello (`input_map_action`).
   - **`irq_scheduler.asm`**: Master IRQ Scheduler a priorità e intervalli (`irq_init`, `irq_add_task`, `irq_remove_task`) che supporta fino a 8 task concorrenti, insieme ad interrupt raster specifici (`irq_set_raster`) e sincronizzazione verticale (`irq_wait_vsync`).

   I moduli del framework di gioco di **c64lib/game/** includono:
   - **`state_machine.asm`**: Macchina a stati finiti (`state_init`, `state_change`, `state_update`, `state_draw`) per gestire l'orchestrazione degli stati di gioco (Boot, Title, Play, GameOver, etc.) tramite una tabella di puntatori a callback.
   - **`sprite_engine.asm`**: Gestore sia di sprite basati su caratteri (blocchi multi-carattere) che di sprite hardware VIC-II (`sprite_draw`, `sprite_clear`, `sprite_animate`, `sprite_move`, `sprite_clip`), ottimizzato per flessibilità e prestazioni. **Include anche un modulo di Sprite Multiplexing** (`sprite_multiplex_init`, `sprite_multiplex_sort`, `sprite_multiplex_apply`) per gestire fino a 16 sprite virtuali ordinati in tempo reale tramite Bubble Sort e mappati dinamicamente sui primi 8 slot fisici del VIC-II.
   - **`collision_system.asm`**: Rilevamento delle collisioni AABB (Axis-Aligned Bounding Box) (`collision_init`, `collision_add`, `collision_remove`, `collision_check_pair`, `collision_check_all`) per un massimo di 24 oggetti attivi, con popolamento automatico di un buffer delle collisioni.
   - **`hud_system.asm`**: Visualizzazione del punteggio (unboxing BCD a 6 cifre), del numero di vite tramite icone e del timer di gioco (`hud_init`, `hud_set_score`, `hud_set_lives`, `hud_set_high_score`, `hud_set_timer`, `hud_draw`, `hud_flash`), con supporto per il posizionamento ad inizio o fine schermo e per effetti di flash colorato.

Il repository include anche **Space Invaders** (`games/invaders/`), un porting completo per Commodore 64, riorganizzato come primo gioco dimostrativo del kit e **interamente basato su `c64lib`** (nessun residuo del codice PET originale).

---

## 🗂️ Struttura del Repository

La struttura del repository è organizzata modularmente per consentire il riutilizzo dei componenti di sviluppo:

```
C64-GameDev/                   # Root del repository
├── c64kit/                     # Libreria Python (framework & emulazione)
│   ├── core/                   # Emulazione hardware di base (Memory, CIA, Interrupt)
│   ├── video/                  # Engine video, VIC-II, colori, sprite
│   ├── audio/                  # SID 3 voci, voice allocation, SFX
│   ├── input/                  # Joystick (porta 1/2), Matrix keyboard
│   ├── game/                   # State machine, Sprite engine, Collision system, HUD
│   ├── tools/                  # Pipeline conversione asset (PNG->charset/sprite), SFX/music compiler
│   ├── build/                  # Pipeline di build automatizzata per emulatori
│   └── testing/                # Test harness per emulatore VICE
├── c64lib/                     # Libreria assembly 6502 riutilizzabile (solo C64)
│   ├── hal/
│   │   └── c64_hardware.inc    # Costanti hardware C64 complete + macro standard
│   ├── core/                   # Gestione memoria, vic_engine, sid_engine, input, irq_scheduler
│   └── game/                   # Sprite engine assembly, collision system, state machine, HUD
├── games/
│   ├── invaders/               # Space Invaders (gioco completo basato su c64lib)
│   └── template/               # Template minimale per l'avvio rapido di nuovi giochi
├── source/
│   ├── pet/                    # [Storico, non compilato] Codice originale PET + documentazione
│   └── legacy/                 # [Storico, non compilato] Primo port monolitico PET→C64
├── tests/
│   └── *.py                    # Test unitari in Python (pytest) per il framework
├── docs/                       # Documentazione delle API Assembly, Python e tutorial
├── Dockerfile                  # Ambiente di sviluppo in container (xa, VICE, Python)
├── docker-compose.yml          # Orchestrazione Docker (volume, build, test, run)
├── Makefile                    # Wrapper per automazione dei comandi (build/test/docker)
├── setup.py                    # Script di installazione della libreria Python c64kit
└── ROADMAP.md                  # Roadmap dettagliata per lo sviluppo del framework
```

---

## 🎮 Space Invaders (Demo Game)

Il classico gioco *Space Invaders* (stile Taito 1978) è il primo gioco completo sviluppato per Commodore 64 usando la modularità di `c64lib`.

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
Due modalità: **nativa** o **Docker** (consigliata, vedi sezione Docker sopra).

#### Modalità nativa
Per programmare e compilare codice C64, assicurarsi di installare l'assemblatore incrociato `xa`:
```bash
sudo apt-get install xa65
```

#### Modalità Docker (consigliata)
```bash
docker compose build
```
Nessuna installazione richiesta sull'host.

### Installazione del framework Python `c64kit`
Il toolkit e la suite di test possono essere installati in modalità di sviluppo locale:
```bash
pip install -e .
```

### Comandi Disponibili

- **Compilare il gioco demo (Space Invaders)**:
  ```bash
  python3 -m c64kit.build.build_system --config games/invaders/c64project.yaml
  ```
  oppure, via Makefile:
  ```bash
  make invaders
  ```
  Questo comando assembla i moduli assembly e genera il file eseguibile `games/invaders/invaders64.prg`, insieme all'immagine disco `.d64` e alla cartuccia `.crt` se configurate nel progetto.

- **Automazione del Packaging (.d64, .crt)**:
  La pipeline di compilazione supporta il packaging nativo delle build. Configurando la sezione `packaging` nel file `c64project.yaml` del tuo gioco:
  ```yaml
  packaging:
    d64: true
    crt: true
  ```
  Il build system rileverà i tool di sistema `c1541` e `cartconv` (dalla suite VICE) e genererà automaticamente un floppy disk `.d64` e una cartuccia `.crt` (formato standard `normal` o custom) ad ogni compilazione.

- **Eseguire la suite di test completa (pytest)**:
  ```bash
  python3 -m pytest
  ```

---

## 🐳 Usare il Progetto con Docker (Consigliato)

Il progetto include un ambiente di sviluppo completo in **Docker** (`Dockerfile` +
`docker-compose.yml`) con tutti gli strumenti necessari già installati:

- **Assemblatore incrociato** `xa` (xa65)
- **Emulatore VICE** (`x64sc`, `x64`, `c1541`, `cartconv`)
- **Xvfb** (virtual framebuffer) per test headless dell'emulatore
- **Python 3.12** + dipendenze `c64kit` (pygame, numpy, PyYAML, Pillow, pytest)
- **zip / unzip** per il packaging

Non serve installare nulla sull'host: basta Docker.

### Prerequisiti

- Docker Engine 24+ e Docker Compose v2+.
- La cartella del progetto viene **montata come volume** in `/workspace`:
  le modifiche locali sono visibili subito nel container e gli artefatti generati
  (`.prg`, `.d64`, `.crt`) restano sulla tua macchina.

### Comandi principali

```bash
# Costruisce l'immagine (la prima volta può richiedere qualche minuto)
docker compose build

# Compila Space Invaders
docker compose run --rm dev python3 -m c64kit.build.build_system --config games/invaders/c64project.yaml

# Compila il template
docker compose run --rm dev python3 -m c64kit.build.build_system --config games/template/c64project.yaml

# Esegue la suite di test completa
docker compose run --rm dev python3 -m pytest

# Apre una shell interattiva dentro il container
docker compose run --rm dev /bin/bash
```

### Comandi Makefile

```bash
make docker-build     # costruisce l'immagine c64gamedev:latest
make docker-invaders  # compila Space Invaders
make docker-template  # compila il template
make docker-test      # esegue pytest
make docker-shell     # apre una shell interattiva
```

### Permessi e UID/GID

Il container crea un utente con lo **stesso UID/GID dell'host** (default 1000/1000)
per poter scrivere nel volume montato. Se il tuo utente ha un UID diverso, passalo
a Docker Compose:

```bash
UID=$(id -u) GID=$(id -g) docker compose build
UID=$(id -u) GID=$(id -g) docker compose run --rm dev ...
```

> **Nota:** la configurazione `docker-compose.yml` usa `network_mode: host` per
> consentire l'accesso al display X dell'host (per eseguire VICE con GUI da dentro
> il container). Per la GUI serve `xhost +local:` sull'host.

---

## 🧰 Creare un Nuovo Gioco (Developer Experience)

Puoi avviare lo sviluppo di un nuovo gioco C64 istantaneamente a partire dal template fornito usando il comando di bootstrap:

```bash
./new_game.sh MioGioco
```

Questo comando clona la struttura del template, la configura per `MioGioco`, e prepara la configurazione di build incrementale. Per compilare il tuo gioco in qualsiasi momento:

```bash
python3 -m c64kit.build.build_system --config games/miogioco/c64project.yaml
```

> **Per una guida dettagliata passo-passo su come creare un nuovo gioco dal template, consulta [`docs/TUTORIAL_30MIN.md`](docs/TUTORIAL_30MIN.md) e [`docs/ASSEMBLY_API.md`](docs/ASSEMBLY_API.md).**

---

## 📝 Documentazione e Roadmap
Per ulteriori dettagli sull'architettura interna, sulle API o sulle fasi future di refactoring, consultare:
- `docs/DOCKER.md` — Guida completa all'ambiente di sviluppo Docker.
- `docs/ASSEMBLY_API.md` — Documentazione dettagliata delle API assembly `c64lib`.
- `docs/PYTHON_API.md` — Documentazione dettagliata delle API Python `c64kit`.
- `docs/TUTORIAL_30MIN.md` — Tutorial "Il tuo primo gioco C64 in 30 minuti".
- `docs/MEMORY_MAP.md` — Mappa e gestione della memoria RAM e Zero Page.
- `source/pet/DOCUMENTATION_PET.md` — Documentazione storica del codice PET originale (riferimento).
- `ROADMAP.md` — Il piano d'azione completo per guidare l'evoluzione del repository.
