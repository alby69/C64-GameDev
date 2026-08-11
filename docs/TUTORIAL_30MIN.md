# TUTORIAL_30MIN.md — Build Your First C64 Game in 30 Minutes

This tutorial will guide you step-by-step through bootstrapping and writing a custom game on Commodore 64 using **c64lib** and **c64kit**.

---

## 🛠️ Step 1: Environment Setup

Ensure you have the Python dependencies and the cross-assembler `xa` installed:

```bash
# Install xa assembler
sudo apt-get install xa65

# Install python dependencies in editable mode
pip install -e .
```

---

## 🚀 Step 2: Bootstrap Your Game

We provide an automatic bootstrapping script `new_game.sh` to initialize projects:

```bash
./new_game.sh Pong
```

This creates a new project directory at `games/pong/` featuring a clean, compiled template game structure.

---

## 📝 Step 3: Understand the Structure

The generated Pong project contains:
* `c64project.yaml`: The project configuration file.
* `src/main.asm`: The main orchestrator file (< 100 LOC) that imports c64lib and custom game states.
* `src/game_states/`: Decoupled assembly state handlers (`state_boot.asm`, `state_play.asm`, etc.).
* `src/entities/`: Custom entity handlers (`player.asm`, `ball.asm`).

---

## ⚡ Step 4: Write Custom Logic

Let's modify the player movement speed inside `games/pong/src/game_states/state_play.asm`.

Open the file and modify the left movement section:

```asm
_play_check_left:
        lda #ACTION_LEFT
        jsr input_map_action
        cmp #1
        bne _play_check_right
        ; Increase speed: decrease X by 2 pixels instead of 1
        dec PLAYER_SPRITE_DEF + SPRITE_X
        dec PLAYER_SPRITE_DEF + SPRITE_X
```

---

## 🏗️ Step 5: Compile Your Game

Compile your game instantly using the incremental build tool:

```bash
python3 -m c64kit.build.build_system --config games/pong/c64project.yaml
```

The compiled game is output at `games/pong/pong.prg`. You can load and run it directly in **VICE (x64sc)** emulator!
