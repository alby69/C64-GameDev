# source/pet/ — Space Invaders per Commodore PET (originale)

Questo è il **codice sorgente originale** di *Space Invaders* per **Commodore PET**,
disassemblato da Dave McMurtrie (agosto 2023).

## File

| File | Descrizione |
|------|-------------|
| `invaders_pet.asm` | Disassembly completo del gioco originale PET (assemblatore `xa`, indirizzamento hardware PET: PIA `$E810`, VIA `$E840`, vettori IRQ `$0090`, screen `$8000`) |
| `DOCUMENTATION_PET.md` | Documentazione tecnica dettagliata del codice PET (struttura, mappa memoria PET, sottosistemi) |

## Nota importante

Questo codice è **solo per riferimento storico e studio**. È codice per **PET**, non
per C64, e **non viene compilato** da alcun build system del repository.

La versione C64 moderna e mantenuta del gioco vive in `games/invaders/`, basata sulla
libreria modulare `c64lib/`.
