# ============================================================================
# Dockerfile — C64 GameDev Kit
# Ambiente di sviluppo completo per giochi Commodore 64 con c64lib/c64kit.
#
# Include:
#   - Ubuntu 24.04 LTS (noble)
#   - Assemblatore incrociato xa (xa65)
#   - Emulatore VICE (x64sc, x64, c1541, cartconv)
#   - Xvfb (virtual framebuffer) per test headless dell'emulatore
#   - Python 3.12 + dipendenze c64kit (pygame, numpy, PyYAML, Pillow, pytest)
#   - zip / unzip per il packaging
#
# Nota: il sorgente del progetto NON viene copiato nell'immagine; viene montato
# a runtime come volume (vedi docker-compose.yml). In questo modo l'immagine è
# riutilizzabile per qualsiasi checkout del progetto.
# ============================================================================

FROM ubuntu:24.04

# ---------------------------------------------------------------------------
# Etichette
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="C64 GameDev Kit"
LABEL org.opencontainers.image.description="C64 game development framework (c64lib assembly + c64kit Python)"
LABEL org.opencontainers.image.source="https://github.com/alby69/C64-GameDev"

# ---------------------------------------------------------------------------
# Variabili d'ambiente
# ---------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/c64kit/bin:${PATH}"

# ---------------------------------------------------------------------------
# Installazione dei pacchetti di sistema
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Strumenti di base
    ca-certificates \
    curl \
    git \
    make \
    zip \
    unzip \
    xvfb \
    # Assemblatore incrociato 6502
    xa65 \
    # Emulatore Commodore 64 (x64sc, c1541, cartconv) — dal repo multiverse
    vice \
    # Python 3.12 e pip
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Virtualenv Python dedicato (Ubuntu 24.04 applica PEP 668: pip di sistema bloccato)
# ---------------------------------------------------------------------------
RUN python3 -m venv /opt/c64kit && \
    /opt/c64kit/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/c64kit/bin/pip install --no-cache-dir \
        "pygame>=2.6.0" \
        "numpy>=2.0.0" \
        "pyyaml>=6.0" \
        "Pillow>=10.0.0" \
        "pytest>=9.0.0"

# ---------------------------------------------------------------------------
# Utente non privilegiato, allineato all'UID/GID dell'host
# (necessario per scrivere nel volume montato: build/artefatti .prg/.d64/.crt)
# ---------------------------------------------------------------------------
ARG USER_UID=1000
ARG USER_GID=1000
# Ubuntu 24.04 base include già un utente con UID/GID 1000 ("ubuntu").
# Creiamo "dev" con lo stesso UID/GID dell'host usando -o (allow duplicate UID)
# così il volume montato è accessibile in scrittura.
RUN useradd -o -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash dev
USER dev
WORKDIR /workspace

# ---------------------------------------------------------------------------
# Comando predefinito
# ---------------------------------------------------------------------------
CMD ["/bin/bash"]