# ****************************************************************************
# Makefile -- C64 GameDev Kit build system wrapper
# ****************************************************************************
# Convenience wrapper around the Python build system (c64kit.build.build_system).
# Each game is defined by its own c64project.yaml under games/.
# ****************************************************************************

INVADERS_CONFIG = games/invaders/c64project.yaml
TEMPLATE_CONFIG = games/template/c64project.yaml

# Default target: build the Space Invaders demo game
all: invaders

# ---------------------------------------------------------------------------
# Build targets
# ---------------------------------------------------------------------------

invaders:
	python3 -m c64kit.build.build_system --config $(INVADERS_CONFIG)

template:
	python3 -m c64kit.build.build_system --config $(TEMPLATE_CONFIG)

build:
	python3 -m c64kit.build.build_system --config $(CONFIG)

# ---------------------------------------------------------------------------
# Test targets
# ---------------------------------------------------------------------------

test:
	python3 -m pytest

# ---------------------------------------------------------------------------
# Run targets (VICE emulator)
# ---------------------------------------------------------------------------

run: invaders
	x64sc games/invaders/invaders64.prg

# ---------------------------------------------------------------------------
# Docker targets
# ---------------------------------------------------------------------------
# Uso:
#   make docker-build    # costruisce l'immagine c64gamedev:latest
#   make docker-invaders # compila Space Invaders dentro il container
#   make docker-test     # esegue pytest dentro il container
#   make docker-shell    # apre una shell interattiva dentro il container
# ---------------------------------------------------------------------------

DOCKER_COMPOSE = docker compose
DOCKER_RUN = $(DOCKER_COMPOSE) run --rm

docker-build:
	$(DOCKER_COMPOSE) build

docker-invaders:
	$(DOCKER_RUN) dev python3 -m c64kit.build.build_system --config $(INVADERS_CONFIG)

docker-template:
	$(DOCKER_RUN) dev python3 -m c64kit.build.build_system --config $(TEMPLATE_CONFIG)

docker-test:
	$(DOCKER_RUN) dev python3 -m pytest

docker-shell:
	$(DOCKER_RUN) dev /bin/bash

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean:
	rm -f games/invaders/invaders64.prg games/invaders/invaders64.d64 games/invaders/invaders64.crt
	rm -f games/template/template.prg games/template/template.d64 games/template/template.crt

.PHONY: all invaders template build test run clean docker-build docker-invaders docker-template docker-test docker-shell
