# source/ — Codice Storico e Riferimenti

Questa cartella contiene **codice di riferimento storico** che **NON** fa parte della
libreria attiva (`c64lib/`, `c64kit/`) né dei giochi dimostrativi (`games/`).

I file qui presenti sono conservati esclusivamente per documentazione, studio del
porting e confronto storico. **Non vengono compilati dal build system** e non sono
necessari per sviluppare nuovi giochi.

## Struttura

```
source/
├── pet/        # Codice originale PET (Space Invaders per Commodore PET)
└── legacy/     # Primo port monolitico PET -> C64 (superato da games/invaders)
```

## Perché esiste questa cartella

Il repository nasce come *Space Invaders* per **Commodore PET** (1980) disassemblato
da Dave McMurtrie. Prima dell'introduzione di `c64lib` e della cartella `games/`,
il gioco è stato portato su C64 con un singolo file monolitico modulare (etichette
`Lxxxx` e variabili `M03xx` ereditate dal PET).

Con il refactoring in libreria generalizzata (`c64lib` + `games/`), il port monolitico
è stato **completamente sostituito** da `games/invaders/`, basato su moduli riutilizzabili.
Il codice storico è stato archiviato qui per:

1. Preservare la storia del progetto e del porting PET→C64.
2. Consentire il confronto tra l'approccio monolitico e quello modulare.
3. Fornire materiale di studio su come era strutturato l'originale PET.

## Cosa NON fare

- **Non includere** questi file in nuovi giochi (`#include` di path in `source/`).
- **Non modificare** questi file per fixare bug dei giochi attivi: le correzioni
  vanno applicate in `c64lib/` o in `games/<gioco>/`.
- **Non compilarli** con il build system (non sono parte di `c64project.yaml`).
