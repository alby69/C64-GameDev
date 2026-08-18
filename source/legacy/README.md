# source/legacy/ — Primo port C64 monolitico (obsoleto)

Questa cartella contiene il **primo port PET → C64** di Space Invaders, organizzato
in moduli (`main.asm`, `video_init.asm`, `game_logic_1.asm`, `game_logic_2.asm`, ...).

## Stato: OBSOLETO

Questo port è stato **completamente sostituito** da `games/invaders/`, che usa la
libreria modulare `c64lib/`. Il codice qui presente:

- Conserva etichette e variabili ereditate dal PET (`L0490`, `L0600`, `M0280`, `SCRD1000`).
- Non è documentato a livello di API.
- Non viene compilato dal build system (`c64project.yaml`).

Viene conservato esclusivamente **come riferimento storico** del processo di porting
PET→C64. Non utilizzarlo per nuovi giochi.

## Perché non cancellarlo

1. Documenta l'evoluzione del progetto (da monolitico a libreria modulare).
2. Permette di confrontare l'approccio "port diretto" con l'approccio "astrazione via c64lib".
3. È il punto di partenza storico da cui è stato tratto `games/invaders/`.
