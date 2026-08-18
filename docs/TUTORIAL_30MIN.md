# TUTORIAL_30MIN.md — Crea il Tuo Primo Gioco C64 in 30 Minuti

Questo tutorial ti guida passo-passo nella creazione di un nuovo gioco per
**Commodore 64** usando il **template** fornito nel progetto, la libreria assembly
`c64lib` e il build system Python `c64kit`.

> **Prerequisito:** un ambiente C64 funzionante. Due opzioni:
> - **Docker (consigliata):** `docker compose build` (vedi `docs/DOCKER.md`). Nessuna installazione sull'host.
> - **Nativa:** installare `xa` e il framework:
>   ```bash
>   sudo apt-get install xa65
>   pip install -e .
>   ```

---

## 🗺️ Struttura del Template

Prima di tutto, guarda com'è fatto il template in `games/template/`:

```
games/template/
├── c64project.yaml              # Configurazione build/packaging del progetto
├── assets/
│   ├── charset.png              # Set di caratteri custom (PNG sorgente)
│   ├── sprites.png              # Sprite sheet (PNG sorgente)
│   └── sfx.yaml                 # Effetti sonori (YAML sorgente)
└── src/
    ├── main.asm                 # Entry point ($0801), inizializzazione, MAIN_LOOP
    ├── game_states/
    │   ├── state_boot.asm       # Stato 0: boot (definisce anche STATE_TABLE)
    │   ├── state_title.asm      # Stato 1: titolo / splash screen
    │   ├── state_menu.asm       # Stato 2: menu (placeholder)
    │   ├── state_play.asm       # Stato 3: loop di gioco principale
    │   ├── state_pause.asm      # Stato 4: pausa
    │   └── state_gameover.asm   # Stato 5: game over
    ├── entities/
    │   ├── player.asm           # Logica del giocatore
    │   └── enemy.asm            # Logica dei nemici
    └── data/
        └── sprite_data.asm      # Definizioni SPRITE (giocatore, ecc.)
```

### La State Machine

Il cuore del template è la **macchina a stati finiti** di `c64lib/game/state_machine.asm`.
Ogni stato ha 4 callback, ordinate in `STATE_TABLE` (definita in `state_boot.asm`):

```asm
STATE_TABLE:
        .word state_boot_enter,     state_boot_exit,     state_boot_update,     state_boot_draw
        .word state_title_enter,    state_title_exit,    state_title_update,    state_title_draw
        .word state_menu_enter,     state_menu_exit,     state_menu_update,     state_menu_draw
        .word state_play_enter,     state_play_exit,     state_play_update,     state_play_draw
        .word state_pause_enter,    state_pause_exit,    state_pause_update,    state_pause_draw
        .word state_gameover_enter, state_gameover_exit, state_gameover_update, state_gameover_draw
        .word state_high_enter,     state_high_exit,     state_high_update,     state_high_draw
```

Gli ID degli stati (da `state_machine.asm`):
| ID | Costante        | Uso                        |
|----|-----------------|----------------------------|
| 0  | `STATE_BOOT`    | Inizializzazione           |
| 1  | `STATE_TITLE`   | Schermata titolo           |
| 2  | `STATE_MENU`    | Menu                       |
| 3  | `STATE_PLAY`    | Gioco                      |
| 4  | `STATE_PAUSE`   | Pausa                      |
| 5  | `STATE_GAMEOVER`| Game over                  |
| 6  | `STATE_HIGH`    | High score (placeholder)   |

La transizione tra stati avviene con `state_change`:
```asm
lda #STATE_PLAY
jsr state_change
```

---

## 🚀 Step 1: Bootstrap del Tuo Gioco

Usa lo script `new_game.sh` per clonare e configurare il template:

```bash
./new_game.sh Pong
```

Questo crea `games/pong/` con:
- `c64project.yaml` rinominato (nome gioco, path, output `.prg`).
- Tutta la struttura `src/` del template.
- La build è subito funzionante.

> Se `new_game.sh` non fosse disponibile, puoi clonare manualmente `games/template/`
> in `games/<nome>/` e modificare `c64project.yaml`.

---

## 🏗️ Step 2: Compila e Verifica la Build di Base

Compila il progetto clonato **prima di modificare qualsiasi cosa**, per essere sicuro
che il template sia sano:

```bash
python3 -m c64kit.build.build_system --config games/pong/c64project.yaml
```

Oppure, da Makefile:

```bash
CONFIG=games/pong/c64project.yaml make build
```

Se tutto è ok, il file `games/pong/pong.prg` viene generato. Puoi già provarlo in VICE:

```bash
x64sc games/pong/pong.prg
```

Vedrai un titolo "TEMPLATE GAME" e, premendo FIRE, un giocatore che si muove
con `A`/`D` (o joystick porta 2).

---

## 📝 Step 3: Personalizza il Titolo

Modifica `games/pong/src/game_states/state_title.asm`:

```asm
mTitleText:
        .byte 16, 15, 14, 7, 0   ; "PONG" in screen code (P=16, O=15, N=14, G=7)
```

I testi sono in **screen code C64** (non ASCII): `A`=1, `B`=2, ... `Z`=26, spazio=32,
`0`=48, ... `9`=57. Per convertire facilmente puoi usare la libreria Python:

```bash
python3 -c "from c64kit.core.utils import ascii_to_screen_code; print(list('PONG') and [ascii_to_screen_code(c) for c in 'PONG'])"
```

---

## ⚡ Step 4: Scrivi la Logica del Gioco

### 4.1 Modifica il comportamento del giocatore

Il movimento del giocatore vive in `state_play.asm`. Per muovere di 2 pixel a sinistra
invece di 1:

```asm
_play_check_right:
        lda #ACTION_RIGHT
        jsr input_map_action
        cmp #1
        bne _play_clipped
        inc PLAYER_SPRITE_DEF + SPRITE_X
        inc PLAYER_SPRITE_DEF + SPRITE_X   ; doppio spostamento
```

### 4.2 Aggiungi un'entità nemica

In `games/pong/src/entities/enemy.asm`:

```asm
enemy_init:
        lda #10
        sta ENEMY_SPRITE_DEF + SPRITE_X
        lda #5
        sta ENEMY_SPRITE_DEF + SPRITE_Y
        rts
```

Aggiungi la definizione `ENEMY_SPRITE_DEF` in `data/sprite_data.asm` (copia lo schema
di `PLAYER_SPRITE_DEF`) e includila in `main.asm` se hai creato un nuovo file di dati.

### 4.3 Collisioni (AABB)

`c64lib/game/collision_system.asm` fornisce collisioni rettangolari per fino a 24 oggetti:

```asm
collision_init
; ... registra gli oggetti con collision_add e verifica con collision_check_all
```

### 4.4 Suoni (SID)

`c64lib/core/sid_engine.asm` espone effetti sonori pronti:

```asm
lda #GAME_SFX_SHOOT
jsr sid_play_effect
```

Definisci gli ID in `data/sfx_data.asm` (es. `GAME_SFX_SHOOT = 0`, `GAME_SFX_EXPLOSION = 1`).

---

## 🎨 Step 5: Aggiorna gli Asset (opzionale)

Il progetto usa asset raster convertiti con la pipeline Python:

```bash
python3 -m c64kit.tools.asset_converter --help
```

Inserisci il tuo charset in `assets/charset.png` e lo sprite sheet in `assets/sprites.png`,
poi rinominali/convertili come previsto dalla configurazione `assets:` del tuo
`c64project.yaml`. (Se non tocchi gli asset, il template usa comunque i dati
definiti in assembly.)

---

## 🔄 Step 6: Ciclo di Vita degli Stati

Ogni stato deve implementare le 4 callback. Ecco lo schema minimo:

```asm
; ENTER: inizializza lo stato (disegna schermo, azzera variabili)
state_play_enter:
        rts

; EXIT: pulizia (es. rimuove sprite dalla schermata)
state_play_exit:
        rts

; UPDATE: logica per-frame (input, movimento, collisioni)
state_play_update:
        rts

; DRAW: disegno a schermo
state_play_draw:
        rts
```

Il `MAIN_LOOP` di `main.asm` chiama automaticamente `state_update` e `state_draw`
dello stato corrente, sincronizzando con `irq_wait_vsync`:

```asm
MAIN_LOOP:
        jsr state_update
        jsr state_draw
        jsr irq_wait_vsync
        jmp MAIN_LOOP
```

---

## 🧱 Step 7: Aggiungi Stati Custom

Per aggiungere uno stato (es. `STATE_LEVELSEL`):

1. Aggiungi la costante in `c64lib/game/state_machine.asm`:
   ```asm
   STATE_LEVELSEL = 7
   ```
2. Crea `games/pong/src/game_states/state_levelsel.asm` con le 4 callback.
3. Registra le callback in `STATE_TABLE` (`state_boot.asm`), in posizione 7.
4. Includi il file in `main.asm` (dopo gli altri stati).

---

## 🏗️ Step 8: Compila e Testa Spesso

Compila ogni volta che modifichi qualcosa:

```bash
python3 -m c64kit.build.build_system --config games/pong/c64project.yaml
```

Esegui i test del framework per non rompere nulla:

```bash
python3 -m pytest
```

---

## 📦 Step 9: Packaging (.prg, .d64, .crt)

Abilita il packaging nel tuo `c64project.yaml`:

```yaml
packaging:
  d64: true
  crt: true        # oppure "normal" per tipo cartuccia custom
```

Il build system genera automaticamente `pong.prg`, `pong.d64` e `pong.crt`.

---

## 💡 Suggerimenti Finali

- **Zero page condivisa:** `$FB`/`$FC` sono i puntatori standard per sprite e tabelle
  (`SPRITE_DEF`, `STATE_TABLE`). Non usarli per altro mentre `sprite_*` è in esecuzione.
- **Colori C64:** vedi `c64lib/hal/c64_hardware.inc` per le costanti (es. `VIC_BG`,
  `VIC_BORDER`, `COLOR_MEM`).
- **Documentazione API completa:** consulta `docs/ASSEMBLY_API.md` per tutte le funzioni
  di `c64lib`, e `docs/PYTHON_API.md` per gli strumenti Python.

---

## 🎯 Riepilogo

| Step | Azione |
|------|--------|
| 1    | `./new_game.sh Pong` |
| 2    | Compila il template invariato |
| 3    | Personalizza titolo (`state_title.asm`) |
| 4    | Scrivi la logica (`state_play.asm`, entità, collisioni, suoni) |
| 5    | Aggiorna asset (opzionale) |
| 6    | Rispetta il ciclo enter/exit/update/draw |
| 7    | Aggiungi stati custom registrandoli in `STATE_TABLE` |
| 8    | Compila e testa spesso |
| 9    | Packaging .prg/.d64/.crt |

Con questo workflow hai un progetto C64 funzionante e testabile in pochi minuti.
Buon divertimento! 🕹️
