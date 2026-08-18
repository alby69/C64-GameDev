"""Unit and integration tests for Phase 8 advanced optimizations and automated packaging.

Verifies cartridge and disk packaging, incremental rebuild tracking, and sprite multiplexing routines compilation.
"""

import os
import shutil
import subprocess
import pytest
from c64kit.build.build_system import load_project_config, build_project, is_rebuild_required


@pytest.mark.skipif(shutil.which("xa") is None, reason="Cross-assembler 'xa' is not installed in system PATH.")
def test_sprite_multiplex_compilation():
    """Ensures that c64lib/game/sprite_engine.asm with the new multiplexer compiles cleanly."""
    asm_file = "c64lib/game/sprite_engine.asm"
    assert os.path.exists(asm_file), f"Assembly file '{asm_file}' does not exist!"

    # Execute xa compiler command in check-only mode (-c)
    cmd = ["xa", "-XMASM", "-c", asm_file]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    assert res.returncode == 0, f"Compilation failed for {asm_file}!\nSTDERR:\n{res.stderr}"


@pytest.mark.skipif(
    shutil.which("xa") is None or shutil.which("c1541") is None or shutil.which("cartconv") is None,
    reason="External tools ('xa', 'c1541', 'cartconv') are not installed in system PATH."
)
def test_packaging_automation():
    """Verifies that invaders project configuration builds and packages successfully to both .d64 and .crt."""
    project_path = "games/invaders/c64project.yaml"
    assert os.path.exists(project_path), f"Project config '{project_path}' does not exist!"

    project = load_project_config(project_path)
    assert project.packaging.get("d64") is True
    assert project.packaging.get("crt") is True

    # Ensure output, d64, and crt paths exist after forcing a build
    success = build_project(project_path, force=True)
    assert success is True, "Failed to compile and package the project!"

    # Expected file paths
    base_dir = os.path.dirname(project.output_file)
    filename_no_ext = os.path.splitext(os.path.basename(project.output_file))[0]
    d64_path = os.path.join(base_dir, f"{filename_no_ext}.d64")
    crt_path = os.path.join(base_dir, f"{filename_no_ext}.crt")

    assert os.path.exists(project.output_file), f"Compiled .prg '{project.output_file}' not found."
    assert os.path.exists(d64_path), f"Packaged .d64 image '{d64_path}' not found."
    assert os.path.exists(crt_path), f"Packaged .crt cartridge '{crt_path}' not found."


@pytest.mark.skipif(
    shutil.which("xa") is None or shutil.which("c1541") is None or shutil.which("cartconv") is None,
    reason="External tools ('xa', 'c1541', 'cartconv') are not installed in system PATH."
)
def test_incremental_packaging_tracking():
    """Verifies that is_rebuild_required correctly detects if packaged targets are deleted."""
    project_path = "games/invaders/c64project.yaml"
    project = load_project_config(project_path)

    # Rebuild to ensure everything is up to date
    build_project(project_path, force=True)
    assert is_rebuild_required(project) is False, "Project should be up to date after force build."

    # Delete the .crt file and ensure rebuild is now required
    base_dir = os.path.dirname(project.output_file)
    filename_no_ext = os.path.splitext(os.path.basename(project.output_file))[0]
    crt_path = os.path.join(base_dir, f"{filename_no_ext}.crt")

    if os.path.exists(crt_path):
        os.remove(crt_path)

    assert is_rebuild_required(project) is True, "Rebuild should be required when packaged cartridge file is missing."

    # Build again to restore
    build_project(project_path)
    assert os.path.exists(crt_path), "Cartridge file should be restored after incremental build."
    assert is_rebuild_required(project) is False, "Project should be up to date again."
