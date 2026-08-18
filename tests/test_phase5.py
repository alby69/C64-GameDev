"""Unit tests for Phase 5 game framework assembly modules.

Checks that all game framework modules in c64lib/game/ compile cleanly using the 'xa' assembler.
"""

import os
import shutil
import subprocess
import pytest


@pytest.mark.skipif(shutil.which("xa") is None, reason="Cross-assembler 'xa' is not installed in system PATH.")
@pytest.mark.parametrize("asm_file", [
    "c64lib/game/state_machine.asm",
    "c64lib/game/sprite_engine.asm",
    "c64lib/game/collision_system.asm",
    "c64lib/game/hud_system.asm",
])
def test_assembly_compilation(asm_file):
    """Ensures that the assembly module compiles cleanly using xa."""
    assert os.path.exists(asm_file), f"Assembly file '{asm_file}' does not exist!"

    # Execute xa compiler command in check-only mode (-c)
    cmd = ["xa", "-XMASM", "-c", asm_file]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Output details on failure
    assert res.returncode == 0, f"Compilation failed for {asm_file}!\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}"
