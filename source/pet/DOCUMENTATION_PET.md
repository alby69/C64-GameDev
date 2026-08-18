# Documentazione del codice Invaders per PET

## Indice

1. [Struttura generale](#1-struttura-generale)
2. [Mappa di memoria PET](#2-mappa-di-memoria-pet)
3. [Avvio e BASIC loader](#3-avvio-e-basic-loader)
4. [Flusso principale del gioco](#4-flusso-principale-del-gioco)
5. [Sottosistemi](#5-sottosistemi)
   - [Interrupt e temporizzazione](#51-interrupt-e-temporizzazione)
   - [Movimento e disegno invaders](#52-movimento-e-disegno-invaders)
   - [Proiettili e collisioni](#53-proiettili-e-collisioni)
   - [Base del giocatore](#54-base-del-giocatore)
   - [Bunker](#55-bunker)
   - [Punteggio e vite](#56-punteggio-e-vite)
   - [Suono](#57-suono)
   - [Trainer del PLAV invader](#58-trainer-del-plav-invader)
6. [Strutture dati](#6-strutture-dati)
7. [Adattamento per C64](#7-adattamento-per-c64)

---

## 1. Struttura generale

Il codice è organizzato come un disco assemblativo unico (`invaders_pet.asm`) che contiene:

- **Codice eseguibile**: da `$0401` a circa `$19F6` (≈5.6 KB)
- **Dati**: da `SCRD1000` (`$1000` nel file) fino a `SCRD1F00` — tabelle di posizioni, sprite in caratteri, stringhe di testo e la schermata "How To Get Sound"

Il linguaggio è **6502 assembly** assemblabile con `xa` (come indicato dalla sintassi `.null`, `format()`, `.byte`, `.word`).

---

## 2. Mappa di memoria PET

### Hardware PET utilizzato

| Indirizzo | Nome            | Funzione                          |
|-----------|-----------------|-----------------------------------|
| `$E810`   | `PIADDRA`       | PIA port A — joystick/suono      |
| `$E812`   | `PIADDRB`       | PIA port B — joystick             |
| `$E840`   | `VIAPB`         | VIA port B — sincronizzazione     |
| `$E848`   | `TIMR2LO`       | VIA timer 2 low — temporizzazione suono |
| `$E84A`   | `VIASHIFTREG`   | VIA shift register — suono        |
| `$E84B`   | `$E84B`         | VIA acr / controllo shift register |
| `$8000`   | Screen memory   | 1000 byte (40×25)                 |

### Variabili in zero page

| Indirizzo | Nome | Uso |
|-----------|------|-----|
| `$0A`-`$0B` | `Z0A/Z0B` | Buffer posizioni invaders (40 byte, 20 coppie) |
| `$50`-`$53` | `Z50-Z53` | Puntatori temporanei per copia schermo |
| `$6E`-`$6F` | `Z6E/Z6F` | Puntatore missile giocatore |
| `$8F`     | `Z8F`    | Contatore per animazione casuale |
| `$B3`     | `ZB3`    | Tipo di sprite da disegnare |
| `$CB`     | `ZCB`    | Usato per sound effects / temporaneo |
| `$D6`-`$D7` | `ZD6/ZD7` | Puntatore posizione corrente proiettile nemico |
| `$FB`-`$FC` | `ZFB/ZFC` | Puntatore posizione invader corrente |

### Variabili in pagina 2 e 3

Tutte le variabili `M02xx` e `M03xx` sono allocazioni in pagina 2 e 3. Le principali:

| Indirizzo | Nome | Uso |
|-----------|------|-----|
| `$0280`   | `M0280` | Direzione movimento invaders (0=destra, $40=sinistra) |
| `$0281`   | `M0281` | Stato esplosione base (alterna frame) |
| `$0282`   | `M0282` | Timer durata esplosione base |
| `$0283`   | `M0283` | Flag: base distrutta |
| `$0286`   | `M0286` | Contatore per animazione invaders |
| `$0287`   | `M0287` | Timer animazione invader bonus |
| `$0288`   | `M0288` | Flag: millepiedi (extra life) attivo |
| `$0289`   | `M0289` | Timer per canzone "mistery" (M03DB) |
| `$0292`-`$0294` | `M0292-4` | Temporizzatori per loop di delay |
| `$02A0`   | `M02A0` | Timer caduta proiettile (conteggio principale) |
| `$02A1`   | `M02A1` | Timer caduta proiettile (sub-conteggio) |
| `$02A2`   | `M02A2` | Timer caduta proiettile (indice suono) |
| `$02A3`   | `M02A3` | Contatore per animazione sonora (passi) |
| `$02A4`   | `M02A4` | Timer suono passo invader |
| `$033C`-`$033D` | `M033C/D` | Punteggio (BCD, 4 cifre) |
| `$033E`-`$033F` | `M033E/F` | High score (BCD, 4 cifre) |
| `$0340`-`$036F` | `M0340+` | Tabella tipi invader (24 byte, 2 byte per invader = 12 invaders) |
| `$03C0`   | `M03C0` | Direzione di marcia invaders (positiva = destra, negativa = sinistra) |
| `$03C1`   | `M03C1` | Frame animazione invaders (0 o 4) |
| `$03C4`-`$03C5` | `M03C4/5` | Temporizzatori ritardo movimento (self-modifying) |
| `$03C6`   | `M03C6` | Precedente direzione di marcia |
| `$03C7`   | `M03C7` | Flag: invaders hanno raggiunto il fondo |
| `$03C8`   | `M03C8` | Contatore per generazione offset casuali |
| `$03C9`   | `M03C9` | Input joystick/PIA port A |
| `$03CA`   | `M03CA` | Posizione X base giocatore (0-8) |
| `$03CB`   | `M03CB` | Timer missile giocatore (tempo prima di sparare) |
| `$03CC`   | `M03CC` | Flag: missile alieno colpito da missile giocatore |
| `$03CD`   | `M03CD` | Contenuto cella sotto proiettile nemico |
| `$03CE`   | `M03CE` | Conteggio invaders rimasti |
| `$03D0`   | `M03D0` | Direzione di movimento per animazione proiettile |
| `$03D1`   | `M03D1` | Flag: proiettile nemico attivo/in attesa |
| `$03D2`   | `M03D2` | Timer proiettile nemico (delay tra spawn) |
| `$03D4`   | `M03D4` | Conteggio proiettili giocatore attivi |
| `$03D5`   | `M03D5` | Indice invader corrente nel ciclo di movimento |
| `$03D6`-`$03D7` | `M03D6/7` | Posizione calcolata per mira proiettile nemico |
| `$03D8`   | `M03D8` | Indice per RNG basato su posizione Z8F |
| `$03D9`   | `M03D9` | Timer esplosione invader (durata animazione) |
| `$03DA`   | `M03DA` | Offset animazione invaders (alterna frame) |
| `$03DB`   | `M03DB` | Numero di vite |
| `$03DC`   | `M03DC` | Posizione X invader bonus (special) |
| `$03DD`   | `M03DD` | Conteggio frame invader bonus |
| `$03DE`   | `M03DE` | Direzione movimento invader bonus |
| `$03E0`   | `M03E0` | Timer disegno invaders (conteggio corrente) |
| `$03E1`   | `M03E1` | Timer disegno invaders (valore di reset) |
| `$03E2`   | `M03E2` | Timer proiettile nemico (conteggio corrente) |
| `$03E3`   | `M03E3` | Timer proiettile nemico (valore di reset) |
| `$03E4`   | `M03E4` | Timer movimento missile (conteggio corrente) |
| `$03E5`   | `M03E5` | Timer movimento missile (valore di reset) |
| `$03E6`   | `M03E6` | Timer invader bonus (conteggio corrente) |
| `$03E7`   | `M03E7` | Timer invader bonus (valore di reset) |
| `$03F0`-`$03F5` | `M03F0-5` | Posizioni e flag 3 missili giocatore |
| `$03F8`   | `M03F8` | Flag: missile giocatore attivo |

---

## 3. Avvio e BASIC loader

```asm
* = $0401
.byte $0d,$04,$0a,$00          ; BASIC line: 10 SYS 1039
.null $9e, format("(%4d)", 1039)
.byte $00,$00
```

Carica il programma con `LOAD` e digita `SYS 1039` (che equivale a `$040F`).

A `$040F` inizia il codice vero:

```asm
START:   LDA #<SCRD1C00    ; Copia la schermata "How To Get Sound"
         STA Z50            ;   da SCRD1C00 ($1C00 nel file)
         LDA #>SCRD1C00     ;   allo schermo video $8000-$83FF
         STA Z51
         LDA #$80
         STA Z53
         ...
L0436:   JSR GET            ; Aspetta che nessun tasto sia premuto
L043B:   JSR GET            ; Poi aspetta che UN tasto sia premuto
         LDA #$93           ; Clear screen (CHR$(147))
         JMP L19D8          ; Vai all'inizializzazione del gioco
```

Il gioco mostra prima una schermata che spiega come attivare il suono sul PET (il "modulo sonoro" del SuperPET), poi aspetta un keypress e parte.

---

## 4. Flusso principale del gioco

```
START → Schermata "How To Get Sound" → keypress → L19D8
  │
  ├─ L19D8: JSR L0E00 (inizializzazione generale)
  │         JSR L0520 (set interrupt → menu handler)
  │         JSR L1900 (schermata comandi tastiera)
  │         JMP L1617
  │
  └─ L1617: TXS (reset stack pointer)
            JSR L1800 (sequenza trainer PLAV invader)
            JMP L19E6
            
  L19E6:   JSR L0530 (set interrupt → game handlers)
           JSR L1700 (inizializza e gioca una partita)
           JSR L0520 (set interrupt → menu handler)
           JMP L19E0 (mostra schermata comandi e ricomincia)
```

### Ciclo di gioco (L1700 / L0490)

```
L1700:  JSR L07E0         ; Clear screen, stop sound
        LDA Z8F           ; Salva RNG state
        STA M03D8
        JSR L0C50         ; Clear screen + init score display
        JSR L0C78         ; Add 0 to score
        JSR L0D60         ; Draw bunkers
        JSR L0800         ; Init invaders positions

L1717:  JSR L0806         ; Move invaders + check collisions
        LDA M03C7         ; Invaders reached bottom?
        BEQ L1717         ; No → loop
        RTS               ; Yes → return (game over / new wave)
```

Ad ogni ondata:

```
L049B:  JSR L0500         ; Set interrupt → game tick
        JSR L0C50         ; Clear screen
        JSR L0C78         ; Reset/add score
        JSR L0D60         ; Draw bunkers
        JSR L0800         ; Init invaders

L04AC:  JSR L0806         ; Move invaders 1 step
        Check fire button (PIADDRB)
        Check M03C7 (bottom reached)
        Check M03CE (aliens count)
        
        If aliens=0 → new wave (L04EC → L04F4 → loop)
        If bottom → L04D0 wait for sequence
        Loop L04AC
```

---

## 5. Sottosistemi

### 5.1 Interrupt e temporizzazione

Il gioco usa un sistema a **timer multipli** basato sull'interrupt del VIA.  
Ci sono diversi "profili" di interrupt:

| Profilo | Vettore | Uso |
|---------|---------|-----|
| `L0500` | `$0090` → `L09FD` | Game loop tick (movimento, proiettili, suono) |
| `L0510` | `$0090` → `$E455` | Interrupt standard Kernal (CRSRBLNK) |
| `L0520` | `$0090` → `L19A0` | Menu handler (aspetta keypress) |
| `L0530` | `$0090` → `L1750` + `$0092` → `L19F6` | Game interrupt (hardware) + BRK handler |

#### Timer `L09FD` (game tick)

```
L09FD:  JSR L0A56         ; Animate + sound
        DEC M03E0         ; Decrement timer drawing
        ...
        DEC M03E2         ; Decrement timer enemy bullet
        ...
        DEC M03E4         ; Decrement timer missile
        ...
        JSR L0780         ; Check/respawn enemy bullet
        JSR L0A60         ; Draw lives
        ...
        DEC M03E6         ; Decrement timer bonus invader
        ...
        JSR L0C93         ; Update score display
        JMP CRSRBLNK      ; Chain to cursor blink
```

#### Timer `L1750` (hardware interrupt - gioco attivo)

Usato durante `L1700` (trainer) con una frequenza più alta. Simile a L09FD ma chiama anche `L1728` (animazione casuale invaders).

### 5.2 Movimento e disegno invaders

#### Inizializzazione posizioni (L0980)

```asm
L0980:  LDX #$00
        LDY M03DA         ; Offset animazione (alterna frame)
L0985:  LDA SCRD1000,X    ; Low byte posizione iniziale
        ADC SCRD1200+$B0,Y ; Aggiunge offset animazione
        STA Z0A,X         ; Salva in buffer posizioni
        LDA SCRD1000+1,X  ; High byte posizione
        STA Z0B,X
        ...
```

Le posizioni iniziali degli invader sono lette dalla tabella `SCRD1000` (40 byte, 20 invaders in 2 righe di 10).

Wait, actually watching the code more carefully: the invaders are drawn using SCRD1100 for the sequence and SCRD1200 for the sprite data.

#### Ciclo di movimento (L0806)

```
L0806:  JSR L0930         ; Check if invaders reached edge, reverse direction
        LDY M0280         ; Load direction offset
L080C:  LDX SCRD1100,Y    ; Get invader type index
        LDA M0340,X       ; Is invader alive?
        BEQ L07FD         ; No → skip to next
        ...
        ; Move invader: add/sub direction to position
        LDA M03C0         ; Direction byte
        BMI L0832         ; Bit 7 set = move left
        CLC
        ADC ZFB           ; Move right
        ...
L0832:  DEC ZFB          ; Move left
        ...
        
        ; Draw sprite at new position
        LDA M0340,X       ; Invader type
        ORA M03C1         ; Add animation frame
        STA ZB3
        JSR L0C00         ; Draw invader sprite
        
        ; Check collision with player missile
        LDA (ZFB),Y       ; Check what's at invader position
        CMP ...           ; Compare with missile characters
        BEQ L087C         ; No collision
        ...
        ; Collision detected!
        INC M03D4         ; Increment missile count
        JSR L08CA         ; Deactivate missile
        INC M03DD         ; Increment bonus counter
```

#### Controllo bordi (L0930)

```asm
L0930:  JSR L09B0         ; Sync with VIA
        ; Scan edges of the invader formation
        ; If any invader touches screen edge, reverse direction
        LDX #$17          ; Check all 24 rows
        ...
        LDA (ZFB),Y       ; Check character at edge
        CMP #$20          ; Space?
        BNE L095D         ; No → edge reached
        
L095D:  LDA M03C0         ; Reverse direction
        EOR #$FF          ; Flip bit 7
        STA M03C0
        LDA #$28
        EOR M0280         ; Flip direction offset
        STA M0280
```

### 5.3 Proiettili e collisioni

#### Missile giocatore (L0B06)

I missili del giocatore sono gestiti da `L0B06`:

```asm
L0B06:  LDX #$00
L0B08:  LDA M03F1,X       ; Missile active? ($01 = active)
        CMP #$01
        BEQ L0B00         ; Yes → skip to next slot
        ; Erase old position
        LDA #$20          ; Space character
        STA (Z6E),Y       ; Erase missile
        ...
L0B34:  ; Move missile up
        LDA Z6E
        SBC #$28          ; Subtract one row
        STA Z6E
        ...
        ; Check collision
        LDA (Z6E),Y
        CMP #$20          ; Space?
        BEQ L0B57         ; Yes → continue moving
        CMP #$60          ; Bunker?
        BEQ L0B60         ; Yes → destroy section
        CMP #$47, #$48    ; Invader?
        BEQ L0BA0         ; Yes → explosion!
        ...
```

Ci sono **3 slot missili** (`M03F0-M03F5`). Ogni slot ha:
- `M03F0,X`: Low byte posizione
- `M03F1,X`: High byte posizione / flag di attività

Quando un missile colpisce un invader:

```asm
L0BA0:  TYA
        PHA
        LDY M03D8         ; RNG index
        LDA $F694,Y       ; Random value
        INC M03D8
        CMP #$50
        BCC L0BB8
        CMP #$A0
        BCC L0BC8
        LDY #$2A          ; Draw explosion "*"
        JSR L065C
```

Wait, `$F694,Y`? That seems like it's reading from the Kernal ROM (or a data area). On PET, `$F694` is in the Kernal ROM. So the game uses a byte from the Kernal ROM as a poor man's RNG.

#### Proiettile nemico (L0780)

```asm
L0780:  LDA ZD7           ; Enemy bullet active?
        BPL L0785         ; Yes → continue
        RTS
L0785:  LDA M03D2         ; Delay timer
        BEQ L078E         ; Expired → fire
        DEC M03D2         ; Decrement delay
        RTS
L078E:  LDA M03C9         ; Read joystick/random input
        AND #$01
        BEQ L079B         ; Skip if bit 0 clear
        ...
L079B:  ; Fire enemy bullet
        LDA M03CA         ; Player X position
        LSR A
        CLC
        ADC #$71
        STA ZD6           ; Calculate bullet column
        LDA #$83          ; Start from bottom of screen
        STA ZD7
```

Il proiettile nemico parte dalla riga in basso e sale verso il giocatore. Se colpisce la base del giocatore, scatta l'esplosione.

### 5.4 Base del giocatore

La base del giocatore è posizionata in base a `M03CA` (0-8, mappato a posizioni X sullo schermo).

Viene disegnata con la funzione `L05B3`:

```asm
L05B3:  ASL A             ; Multiply by 4 (columns per position)
        ASL A
        ASL A
        ASL A
        TAY
        TXA               ; X position / 2
        LSR A
        TAX
L05BB:  LDA SCRD1100+$80,Y ; Get character data for base
        STA $8398,X       ; Draw at screen position
        ...
```

Il giocatore si muove con `L0580` che legge il joystick PIA:

```asm
L0580:  LDA #$04
        STA PIADDRA       ; Set PIA direction
L0585:  LDA PIADDRB       ; Read joystick
        CMP PIADDRB       ; Debounce
        BNE L0585
        STA M03C9         ; Store state
        ; Convert to position:
        ; Bits 0-5 encode direction
        ORA #$3F
        CMP #$7F          ; Left?
        BNE L05A1
        CPX #$3F
        BEQ L05AD
        INX               ; Move left
L05A1:  CMP #$BF          ; Right?
        ...
        DEX               ; Move right
```

### 5.5 Bunker

I bunker sono disegnati da `L0D60`:

```asm
L0D60:  LDA #$FF
        STA ZFB           ; Bunker 1: row $82FF
        LDA #$82
        STA ZFC
        JSR L0D88         ; Draw bunker pattern
        LDA #$06
        STA ZFB           ; Bunker 2: row $8306
        LDA #$83
        STA ZFC
        JSR L0D88
        ...
```

`L0D88` copia i byte dalla tabella `SCRD1200+$82` e li scrive in posizioni calcolate con offset dalla tabella `SCRD1200+$83`.

I bunker sono rappresentati dal carattere PET `$60` (un rettangolo pieno).

### 5.6 Punteggio e vite

Il punteggio è in **BCD** a 4 cifre in `M033C` (low) e `M033D` (high).

```asm
L0C78:  JSR L0CE0         ; Convert invader type to points
        ASL A
        SED
        CLC
        ADC M033C         ; Add to low byte
        STA M033C
        BCC L0C92
        LDA M033D
        ADC #$00          ; Carry to high byte
        STA M033D
L0C92:  CLD
```

Il display del punteggio `L0C93` usa `L0CB6` per convertire nibble in ASCII e scrivere a schermo:

```asm
L0CB6:  AND #$0F
        ORA #$30          ; Convert to PETSCII digit
        STA $8006,X       ; Write to screen at score position
        DEX
        RTS
```

Il **high score** (`M033E/M033F`) viene aggiornato a fine partita in `L18C6`.

### 5.7 Suono

Il suono su PET usa il **VIA shift register** e **timer 2**:

```asm
L0550:  LDA M03DC         ; Bonus invader active?
        BPL L0556
        RTS               ; No → skip
L0556:  INC M02A3         ; Step counter
        LDA M02A3
        AND #$0F
        TAX
        LDA SCRD1300+$C8,X ; Get frequency from table
        LDX M03CC         ; Flag: invader hit by missile?
        BEQ L056A
        CLC
        ADC #$50          ; Higher pitch when hit
L056A:  STA TIMR2LO       ; Set VIA timer 2 frequency
        RTS
```

Ci sono **5 tipi di suoni**:
1. **Passo invader** (`L0550`): frequenza ciclica da tabella `SCRD1300+$C8`
2. **Sparo giocatore**: shift register + timer
3. **Esplosione invader** (`L0550` con `M03CC`=1): tono più alto
4. **Movimento invader bonus** (`L0F70` con `L0FB8`): pattern sonoro speciale
5. **Suono millepiedi/vite extra**: `$E84B` + `VIASHIFTREG`

### 5.8 Trainer del PLAV invader

La sequenza `L1800` (PLAV INVADER TRAINER) è un'introduzione animata che mostra il boss "PLAV" invader:

```asm
L1800:  JSR L16C0         ; Clear screen
        ; Print title
        LDA #<SCRD1400
        STA ZFB
        LDA #>SCRD1400
        STA ZFC
        JSR L1600         ; Print string
        ; Draw PLAV invader walking across screen
        LDA #$03
        STA ZB3           ; Type 3 = PLAV
L1836:  JSR L0C00         ; Draw PLAV at current position
        ...
        DEX               ; 17 steps
        DEC ZFB           ; Move left
        BNE L1836
        ; Then draw it moving right, then left again
        ...
```

Il PLAV invader è lo sprite più grande (tipo 3 nel sistema di sprite).

---

## 6. Strutture dati

### `SCRD1000` — Posizioni iniziali invaders

40 byte (20 coppie low/high) che definiscono le posizioni di partenza dei 20 invaders.  
I valori sono indirizzi di memoria video PET ($80xx-$83xx).

```
.byte $fc,$81,$f8,$81,$f4,$81,...  → posizioni spaziate 4 byte
```

### `SCRD1100` — Tabella indice invaders per posizione

Mappa ogni colonna della formazione al tipo di invader (indice in `M0340`).

Contiene anche i dati sprite della base del giocatore (a partire da `SCRD1100+$80`).

### `SCRD1200` — Sprite in caratteri + dati di gioco

Contiene:
- Dati sprite per i 3 tipi di invader (2 frame ciascuno)
- Dati sprite per la base del giocatore
- Tabella punteggi invader
- Dati bunker
- Costanti di gioco

I primi byte definiscono gli sprite:

```
; 3 tipi di invader × 2 frame × 4 righe = 24 byte
; INVADER TIPO 1 (piccolo):
.byte $00,$20,$20,$20,$20,$20,$20,$ff,$e3,$7f,$20,$20,$ff,$f9,$7f,$20
.byte $00,$20,$20,$20,$20,$20,$20,$fc,$99,$fe,$20,$20,$fb,$20,$ec,$20
...
```

### `SCRD1300` — Dati vari + stringhe

Contiene:
- `$00-$0F`: Tabella frequenze suono (`SCRD1300+$C8`)
- `$10`: Stringa "SCORE" etc.
- `$18`: Stringa menu "PUSH ANY KEY TO START"
- `$2E`: Stringa informazioni
- `$70-$7F`: Testo display "HIGH" e "SCORE"
- `$80+`: Tabella animazione casuale (per RNG)
- `$C8+`: Tabella frequenze timer suono
- `$D7+`: Tabella frequenze per passo invader
- `$E7+`: Tabella frequenze bonus

### `SCRD1350` — Schermata "GAME OVER"

```
.byte $13,$11,$11,$1d,...  → PETSCII per "GAME OVER" con cornice
```

### `SCRD1400` — Schermata trainer PLAV

```
"PLAV INVADERS"
"SPACE INVADERS"
"MYSERTY ? 30 POINTS"
...
```

### `SCRD1500` — Schermata comandi

```
"KEYBOARD COMMANDS"
" 4  MOVE LEFT"
" 6  MOVE RIGHT"
" A  FIRE BEAM"
...
```

### `SCRD1C00`-`SCRD1F00` — Schermata "How To Get Sound"

Una schermata informativa su come attivare il modulo sonoro sul SuperPET.  
Contiene:
- Titolo: "* HOW TO PRODUCE SOUND EFFECTS *"
- Una rappresentazione grafica delle connessioni DIN
- Testo esplicativo

---

## 7. Adattamento per C64

Per portare il gioco su Commodore 64, le modifiche necessarie sono:

### 7.1 Memoria video
| PET | C64 |
|-----|-----|
| `$8000` | `$0400` |
| offset: `$8000` | offset: `$0400` |

Tutti gli indirizzi `$80xx` e `$83xx` vanno convertiti sottraendo `$7C00`.

### 7.2 Vettori interrupt
| PET | C64 |
|-----|-----|
| `$0090/$0091` (IRQ) | `$0314/$0315` |
| `$0092/$0093` (BRK) | `$0318/$0319` (NMI) |

### 7.3 Hardware
| PET | C64 | Note |
|-----|-----|------|
| `$E810` PIADDRA | `$DC00` CIA1 PRA | Joystick port 2 |
| `$E812` PIADDRB | `$DC01` CIA1 PRB | Joystick port 1 |
| `$E840` VIAPB | si può omettere | Sincronizzazione |
| `$E848` TIMR2LO | `$D400+` SID | Usare SID per suono |
| `$E84A` VIASHIFTREG | `$D418` SID vol | Volume/effetti |
| `$E84B` | `$D406` SID | Frequenza/controllo |

### 7.4 Character set
Il PET ha un set di caratteri diverso dal C64. I caratteri grafici PET usati:
- `$60` = rettangolo pieno (C64: diverso)
- `$7F` = custom?  
- `$A0` = mezzo quadrato (C64: diverso)
- Invaders e base usano pattern di caratteri che vanno ricreati come sprite C64 o ridefiniti in RAM del character set

Una soluzione pratica è **copiare il character set PET nella RAM del C64** (indirizzo `$3800` o `$3000`) oppure usare il set di caratteri PETSCII del C64 in modalità uppercase/graphics.

### 7.5 RNG
Il gioco usa `LDA $F694,Y` per il RNG (leggendo dal Kernal PET). Su C64 va sostituito con una lettura da `$D41B` (SID random number generator) o da `$A2` (timer IRQ).

### 7.6 BASIC loader
Il nuovo SYS address dipende da dove verrà ricollocato il codice (es. `$0801` per C64 BASIC).
