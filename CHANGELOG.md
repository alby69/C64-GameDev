# Changelog

Tutte le modifiche rilevanti di questo progetto saranno documentate in questo file.
Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/) e [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-08-18

### Aggiunto
- Manifest plugin (`plugin.yaml`) per l'integrazione dichiarativa nell'SDK.
- Docker environment (`Dockerfile` e `docker-compose.yml`) con supporto per `xa65`, VICE (`x64sc`, `c1541`, `cartconv`), `xvfb`, Python 3.12 e `c64kit`.
- Pipeline CI con GitHub Actions (`.github/workflows/ci.yml`) per la build automatica dell'assembly C64, test e packaging.
- Sprite Multiplexer in `c64lib/game/sprite_engine.asm` per gestire fino a 16 sprite virtuali ordinati dinamicamente.
- Packaging automatico di immagini disco `.d64` e cartucce `.crt` nel build system Python (`c64kit/build/build_system.py`).
- Guida dettagliata all'ambiente Docker (`docs/DOCKER.md`) e aggiornamento del tutorial `docs/TUTORIAL_30MIN.md`.

### Modificato
- Riorganizzato il codice assembly: archiviati il disassemblato PET originale (`source/pet/`) e il port monolitico legacy (`source/legacy/`).
- Refactoring del repository con struttura C64-only in `c64lib/` e `games/`.
- Import pigro (PEP 562) in `c64kit/__init__.py` per disaccoppiare il build system dalla dipendenza runtime di Pygame.
- Marcatori `@pytest.mark.skipif` condizionali sui test di assembly e packaging per skippare in assenza dei tool di sistema (`xa`, `c1541`, `cartconv`).
