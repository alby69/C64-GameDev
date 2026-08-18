# DOCKER.md — Ambiente di Sviluppo in Container

Questa guida spiega come usare l'ambiente di sviluppo **Docker** del progetto
C64 GameDev Kit. Tutto il tooling necessario è preinstallato nell'immagine:

| Strumento | Scopo |
|-----------|-------|
| `xa` (xa65) | Assemblatore incrociato 6502 per C64 |
| `x64sc` / `x64` | Emulatore Commodore 64 (VICE) |
| `c1541` | Creazione/scrittura immagini disco `.d64` |
| `cartconv` | Conversione `.prg` → cartucce `.crt` |
| `xvfb-run` | Virtual framebuffer X per test headless dell'emulatore |
| Python 3.12 + `c64kit` | Framework, build system e test |
| `zip` / `unzip` | Packaging distribuzione |

---

## 1. Prerequisiti

- **Docker Engine 24+**
- **Docker Compose v2+**

Verifica con:

```bash
docker --version
docker compose version
```

---

## 2. Prima Build

Dalla **root del progetto**:

```bash
docker compose build
```

La prima build può richiedere qualche minuto (download base image Ubuntu 24.04 +
installazione pacchetti). Le build successive usano la cache.

---

## 3. Comandi di Uso Quotidiano

### Compilare Space Invaders

```bash
docker compose run --rm dev python3 -m c64kit.build.build_system --config games/invaders/c64project.yaml
```

Output generato in `games/invaders/`:
- `invaders64.prg` — programma eseguibile
- `invaders64.d64` — immagine disco (se packaging abilitato)
- `invaders64.crt` — cartuccia (se packaging abilitato)

### Compilare il template

```bash
docker compose run --rm dev python3 -m c64kit.build.build_system --config games/template/c64project.yaml
```

### Eseguire i test

```bash
docker compose run --rm dev python3 -m pytest
```

### Compilare un nuovo gioco

Dopo aver creato un gioco con `./new_game.sh MioGioco` (eseguito sull'host o nel
container), compila con:

```bash
docker compose run --rm dev python3 -m c64kit.build.build_system --config games/miogioco/c64project.yaml
```

### Shell interattiva

```bash
docker compose run --rm dev /bin/bash
```

Da dentro la shell puoi usare `make`, `xa`, `x64sc`, `python3` ecc. normalmente.

---

## 4. Comandi Makefile

| Comando | Equivalente |
|---------|-------------|
| `make docker-build` | `docker compose build` |
| `make docker-invaders` | build di `games/invaders` |
| `make docker-template` | build di `games/template` |
| `make docker-test` | `docker compose run --rm dev python3 -m pytest` |
| `make docker-shell` | `docker compose run --rm dev /bin/bash` |

---

## 5. Volume e Persistenza

Il `docker-compose.yml` monta la **cartella del progetto** (`.`) come volume in
`/workspace`:

```yaml
volumes:
  - .:/workspace
```

Conseguenze:

- Le modifiche ai sorgenti sull'host sono **immediatamente visibili** nel container
  (niente rebuild dell'immagine a ogni cambio).
- Gli artefatti generati (`.prg`, `.d64`, `.crt`) vengono scritti **sulla tua
  macchina**, non dentro il container.
- L'immagine è riutilizzabile per qualsiasi checkout del progetto.

---

## 6. UID/GID e Permessi

Il Dockerfile crea un utente con lo **stesso UID/GID dell'host** (default
1000/1000) così può scrivere nel volume. Se il tuo utente ha UID/GID diversi:

```bash
UID=$(id -u) GID=$(id -g) docker compose build
UID=$(id -u) GID=$(id -g) docker compose run --rm dev ...
```

> Sul sistema `ubuntu:24.04` esiste già un utente con UID 1000; il Dockerfile usa
> `useradd -o` per creare `dev` con lo stesso UID senza conflitti.

---

## 7. Eseguire VICE con GUI dal Container

Per lanciare `x64sc` con finestra dal container:

1. Abilita l'accesso al display X dell'host:
   ```bash
   xhost +local:
   ```
2. Avvia il gioco:
   ```bash
   docker compose run --rm dev x64sc games/invaders/invaders64.prg
   ```

Il `docker-compose.yml` usa `network_mode: host` per semplificare questo accesso.
Per i test headless (che usano `xvfb-run`) non serve alcuna configurazione.

---

## 8. Risoluzione Problemi

| Problema | Soluzione |
|----------|-----------|
| `permission denied` scrivendo `.prg` | Ricostruisci con il tuo UID/GID (sezione 6) |
| Build lenta | La prima build scarica i pacchetti; le successive usano la cache |
| `xa: command not found` | Dentro il container `xa` è installato; verifica di usare `docker compose run --rm dev ...` |
| GUI VICE non visibile | Esegui `xhost +local:` sull'host prima di lanciare `x64sc` |

---

## 9. Architettura dei File

| File | Scopo |
|------|-------|
| `Dockerfile` | Immagine Ubuntu 24.04 + xa65 + VICE + Xvfb + Python venv (`/opt/c64kit`) |
| `docker-compose.yml` | Servizio `dev` con volume del progetto, network host, UID/GID configurabili |

Per la guida completa allo sviluppo di giochi, vedi `docs/TUTORIAL_30MIN.md`.