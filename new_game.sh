#!/bin/bash
# ============================================================================
# new_game.sh -- Automation tool to bootstrap new C64 games from the template
# ============================================================================

set -e

if [ -z "$1" ]; then
    echo "Usage: ./new_game.sh <GameName>"
    echo "Example: ./new_game.sh Pong"
    exit 1
fi

GAME_NAME="$1"
GAME_NAME_LOWER=$(echo "$GAME_NAME" | tr '[:upper:]' '[:lower:]')

TARGET_DIR="games/$GAME_NAME_LOWER"

if [ -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' already exists."
    exit 1
fi

echo "Creating new game project: $GAME_NAME inside $TARGET_DIR..."

# Copy template structure
mkdir -p "games"
cp -r games/template "$TARGET_DIR"

# Customize project configuration file
if [ -f "$TARGET_DIR/c64project.yaml" ]; then
    # Replace project names
    sed -i "s/C64 Template Game/$GAME_NAME Game/g" "$TARGET_DIR/c64project.yaml"
    sed -i "s/games\/template/games\/$GAME_NAME_LOWER/g" "$TARGET_DIR/c64project.yaml"
    sed -i "s/template.prg/$GAME_NAME_LOWER.prg/g" "$TARGET_DIR/c64project.yaml"
fi

echo "Project successfully bootstrapped!"
echo "To build your new game, run:"
echo "  python3 -m c64kit.build.build_system --config $TARGET_DIR/c64project.yaml"
