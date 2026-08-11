"""Unit tests for Phase 4 core assembly modules.

Checks that all core modules in c64lib/core/ compile cleanly using the 'xa' assembler.
"""

import os
import subprocess
import pytest


@pytest.mark.parametrize("asm_file", [
    "c64lib/core/memory_manager.asm",
    "c64lib/core/vic_engine.asm",
    "c64lib/core/sid_engine.asm",
    "c64lib/core/input_system.asm",
    "c64lib/core/irq_scheduler.asm",
])
def test_assembly_compilation(asm_file):
    """Ensures that the assembly module compiles cleanly using xa."""
    assert os.path.exists(asm_file), f"Assembly file '{asm_file}' does not exist!"

    # Execute xa compiler command in check-only mode (-c)
    cmd = ["xa", "-XMASM", "-c", asm_file]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Output details on failure
    assert res.returncode == 0, f"Compilation failed for {asm_file}!\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}"
