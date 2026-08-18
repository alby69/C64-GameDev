"""Unit tests for Phase 6 components.

Verifies the build pipeline and compilation of the refactored Space Invaders game and the developer template.
"""

import os
import pytest
from c64kit.build.build_system import load_project_config, build_project, is_rebuild_required


def test_invaders_project_configuration():
    """Verifies that the invaders c64project.yaml compiles cleanly using build_project."""
    project_path = "games/invaders/c64project.yaml"
    assert os.path.exists(project_path), f"Project config '{project_path}' does not exist!"

    project = load_project_config(project_path)
    assert project.name == "Space Invaders C64"
    assert project.version == "1.2.0"
    assert project.assembler == "xa"
    assert "c64lib" in project.source_dirs

    # Build the project
    success = build_project(project_path, force=True)
    assert success is True, "Failed to compile the refactored Space Invaders project!"
    assert os.path.exists(project.output_file), f"Compiled output '{project.output_file}' was not created!"


def test_template_project_configuration():
    """Verifies that the template c64project.yaml compiles cleanly using build_project."""
    project_path = "games/template/c64project.yaml"
    assert os.path.exists(project_path), f"Project config '{project_path}' does not exist!"

    project = load_project_config(project_path)
    assert project.name == "C64 Template Game"
    assert project.version == "1.0.0"

    # Build the project
    success = build_project(project_path, force=True)
    assert success is True, "Failed to compile the template project!"
    assert os.path.exists(project.output_file), f"Compiled output '{project.output_file}' was not created!"
