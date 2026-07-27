# Invaders — PET Disassembly & C64 Port

**Invaders** è il classico gioco *Space Invaders* (stile Taito 1978) disassemblato per **Commodore PET** da Dave McMurtrie (Agosto 2023) ed evoluto in un port completo e ottimizzato per **Commodore 64**.

Questo repository contiene:
- `invaders.asm` — Disassemblaggio completo e documentato del gioco originale per PET.
- `invaders_c64.asm` — Versione per **Commodore 64** con supporto a colori (Color RAM), suono SID multicanale, e controlli ottimizzati.

---

## 🎮 Come Giocare su Commodore 64

### Avvio del Gioco
Il gioco è precompilato nel file `invaders64.prg`. Per caricarlo ed eseguirlo su un emulatore (come VICE x64sc) o su hardware reale:
```
LOAD "INVADERS64.PRG",8,1
RUN
```
*(Oppure `SYS 2062` se caricato manualmente in memoria)*

All'avvio, il gioco mostrerà la schermata iniziale "**How To Get Sound**". Premere un tasto qualsiasi per procedere al menu di gioco principale e avviare la partita.

### Controlli di Gioco

Il porting per Commodore 64 supporta controlli flessibili simultanei, permettendo di giocare sia tramite tastiera sia con un joystick inserito nella porta 2.

| Comando Tastiera | Comando Joystick (Porta 2) | Azione |
|------------------|---------------------------|--------|
| `A`              | **Sinistra**              | Muovi la base a sinistra |
| `D`              | **Destra**                | Muovi la base a destra |
| `J` oppure `Spazio`| **Pulsante Fuoco**      | Spara il raggio laser |
| `P`              | —                         | Metti in Pausa / Riprendi il gioco |
| `F1`             | —                         | Riavvio Rapido (Quick Restart) da qualsiasi schermata |

---

## 🛠️ Compilazione e Build System

Il progetto include un `Makefile` pronto per l'uso per l'assemblatore incrociato `xa` (xa65).

### Prerequisiti
Assicurarsi di avere installato l'assemblatore `xa`. Su sistemi Debian/Ubuntu è possibile installarlo con:
```bash
sudo apt-get install xa65
```

### Comandi Makefile

- **Compilare il gioco**:
  ```bash
  make
  ```
  Questo comando assemblerà `invaders_c64.asm` e genererà l'eseguibile pronto `invaders64.prg`.

- **Ripulire gli artefatti**:
  ```bash
  make clean
  ```

- **Avviare il gioco con VICE x64sc**:
  ```bash
  make run
  ```

---

## 📊 Caratteristiche del Porting PET → C64

Il porting è stato completato e rifinito per sfruttare al meglio l'hardware del Commodore 64 garantendo al contempo fedeltà assoluta al gameplay originale:

1. **Memoria Video & Schermate**:
   - Conversione degli indirizzi dello schermo PET (`$8000–$83FF`) negli indirizzi standard del C64 (`$0400–$07FF`).
   - Sincronizzazione tramite raster VIC (`VIC_RASTER` a `$F8`) per garantire un timing fluido e stabile indipendentemente dal modello C64 PAL/NTSC.

2. **C64 Color RAM**:
   - Inizializzazione automatica della Color RAM (`$D800–$DBE7`) all'avvio.
   - Sfondo nero con HUD (punteggio e vite) in bianco e campo di gioco/bunker/invaders in verde brillante per richiamare lo stile dei monitor a fosfori verdi arcade originali.

3. **Character Set Personalizzato**:
   - Copia della Character ROM originale del C64 e sovrascrittura parziale nell'area dei caratteri grafici PET (`$60-$7F`) a `$3800` per riprodurre fedelmente la grafica PETSCII originale dei bunker e degli sprite degli invasori.

4. **Suono SID Evoluto**:
   - Conversione del sistema sonoro VIA del PET per utilizzare il chip SID del C64 (`$D4xx`).
   - Generazione di effetti sonori per passi degli invasori, spari, esplosioni e jingle di game over stabili e definiti.

5. **Self-Modifying Code (SMC)**:
   - Preservata la logica di self-modifying code originale per la regolazione dinamica del delay di movimento degli invasori (`L08F3_SELF`) e del limite dei proiettili contemporanei (`L08D1_SELF`). Trattandosi di esecuzione in RAM sul C64, questi blocchi funzionano in modo sicuro e sono pienamente documentati nel codice sorgente.

6. **Stabilità Core**:
   - Correzione del BRK/NMI interrupt handler (`L19F6`) per ripristinare correttamente lo stack pointer (`LDX #$FF; TXS`), prevenendo crash e instabilità in caso di riavvii o interrupt multipli.

---

## 🐛 Troubleshooting

- **I caratteri appaiono vuoti o con colori casuali**:
  - Assicurarsi di aver eseguito l'ultima build che inizializza la Color RAM. Il gioco inizializza automaticamente l'area colore `$D800-$DBFF` all'avvio del programma.
  - Se si avvia da monitor esadecimale o dopo un reset hardware parziale, rieseguire da `RUN` o ricaricare il file `.prg` per forzare l'inizializzazione corretta.

- **I controlli a tastiera non rispondono**:
  - Il gioco legge i tasti tramite la matrice di scansione standard del C64. Accertarsi che l'emulatore catturi correttamente l'input della tastiera del PC (es. impostando la modalità keyboard corretta in VICE).

---

## 📝 Crediti

- **Dave McMurtrie** (`dave@commodore.international`): Ricostruzione e documentazione del disassemblaggio PET originale (Agosto 2023).
- **Adattamento, Miglioramento e Porting C64**: Sviluppato e completato con successo in questo repository.
