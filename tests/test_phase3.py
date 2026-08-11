"""Unit tests for Phase 3 components.

Verifies the Asset Converter, SID Music/SFX Compiler, Build System, and VICE Harness.
"""

import os
import pytest
import numpy as np
from PIL import Image
from c64kit.tools.asset_converter import (
    C64_PALETTE,
    get_closest_color,
    dither_image,
    convert_to_charset,
    convert_to_sprites,
    generate_html_preview,
    export_data,
)
from c64kit.tools.sid_compiler import (
    note_to_sid_freq,
    waveform_to_byte,
    compile_sfx_to_asm,
    compile_music_to_asm,
    compile_sound_config,
)
from c64kit.build.build_system import (
    C64Project,
    load_project_config,
    is_rebuild_required,
)
from c64kit.testing.vice_harness import VICEHarness, SIDState


# ============================================================================
# TASK 3.1 TESTS: Asset Converter Pipeline
# ============================================================================

def test_asset_converter_charset_and_sprite():
    """Verifies color distance, image dithering, charset deduplication, and sprite generation."""
    # 1. Color distance check
    assert get_closest_color((0, 0, 0)) == 0       # BLACK
    assert get_closest_color((255, 255, 255)) == 1 # WHITE

    # 2. Dithering check
    img = Image.new("RGB", (16, 16), (130, 0, 0))  # Near C64 RED (136, 0, 0)
    indexed, rgb_out = dither_image(img)
    assert indexed.shape == (16, 16)
    assert indexed[0, 0] == 2  # RED

    # 3. Charset deduplication check
    # Create two identical 8x8 character blocks
    indexed_charset = np.zeros((8, 16), dtype=np.uint8)
    indexed_charset[0, 0] = 1
    indexed_charset[0, 8] = 1  # Block 1 and Block 2 are identical

    unique_chars, tilemap, meta = convert_to_charset(indexed_charset, bg_color=0)
    # Deduplication should reduce 2 blocks to 1 unique character
    assert len(unique_chars) == 1
    assert tilemap == [0, 0]
    assert meta["saving_ratio"] == 0.5

    # 4. Sprite conversion (24x21 blocks)
    indexed_sprites = np.zeros((21, 24), dtype=np.uint8)
    indexed_sprites[0, 0] = 1  # Top-left of first sprite is foreground
    sprites = convert_to_sprites(indexed_sprites, sprite_color=1)
    assert len(sprites) == 1
    assert len(sprites[0]) == 64  # 64 bytes total including padding
    assert sprites[0][0] == 0x80  # First bit of first row is set (10000000 -> 0x80)

    # 5. HTML Preview generation
    preview_file = "test_preview.html"
    if os.path.exists(preview_file):
        os.remove(preview_file)
    generate_html_preview(indexed, preview_file)
    assert os.path.exists(preview_file)
    with open(preview_file, "r", encoding="utf-8") as f:
        html_content = f.read()
    assert "C64 Asset Preview" in html_content
    os.remove(preview_file)

    # 6. Export format checks
    data_block = [bytes([0x01, 0x02, 0x03, 0x04])]
    asm_str = export_data(data_block, "asm", label="my_label")
    assert "my_label:" in asm_str
    assert ".byte $01, $02, $03, $04" in asm_str

    c_str = export_data(data_block, "c", label="my_label")
    assert "const unsigned char my_label[]" in c_str
    assert "0x01, 0x02, 0x03, 0x04" in c_str


# ============================================================================
# TASK 3.2 TESTS: SID Compiler
# ============================================================================

def test_sid_compiler():
    """Verifies pitch mapping, waveforms mapping, sfx parsing, and pattern compilation."""
    # 1. Pitch / note frequency checks
    assert note_to_sid_freq("A-4") == 7492  # 440Hz * 17.0284 = 7492.496
    assert note_to_sid_freq("C-4") == 4455  # 261.63Hz * 17.0284 = 4455
    assert note_to_sid_freq("...") == 0

    # 2. Waveforms check
    assert waveform_to_byte("noise") == 0x80
    assert waveform_to_byte("sawtooth") == 0x20
    assert waveform_to_byte(["noise", "sawtooth"]) == 0xA0

    # 3. SFX compiling check
    sfx_config = {
        "sfx": {
            "pew": {
                "waveform": "pulse",
                "attack": 0,
                "decay": 8,
                "sustain": 0,
                "release: ": 0,
                "freq_start": "C-4",
                "freq_end": "C-3",
                "duration_ms": 100,
            }
        }
    }
    asm_output = compile_sound_config(sfx_config)
    assert "sfx_pew:" in asm_output
    assert ".byte $40" in asm_output  # pulse
    assert ".byte $08" in asm_output  # Attack 0, Decay 8
    assert "SFX_TABLE:" in asm_output

    # 4. Music compilation check
    music_config = {
        "music": {
            "bpm": 120,
            "patterns": [
                [
                    ["C-4", 1, 0x00],
                    ["E-4", 1, 0x00],
                ]
            ]
        }
    }
    music_output = compile_sound_config(music_config)
    assert "music_pattern_0:" in music_output
    assert "MUSIC_BPM = 120" in music_output


# ============================================================================
# TASK 3.3 TESTS: Build System
# ============================================================================

def test_build_system():
    """Verifies c64project.yaml loading and incremental rebuild checking."""
    # Write a test configuration YAML file
    test_yaml_path = "test_config.yaml"
    if os.path.exists(test_yaml_path):
        os.remove(test_yaml_path)

    config_content = """
project:
  name: "Build Test Project"
  version: "1.0.0"
  target: c64

build:
  assembler: xa
  flags: [-XMASM]
  source_dirs: ["."]
  main: main.asm
  output: build/build_test.prg

assets:
  charset: test_charset.png

testing:
  emulator: x64sc
"""
    with open(test_yaml_path, "w", encoding="utf-8") as f:
        f.write(config_content)

    try:
        project = load_project_config(test_yaml_path)
        assert project.name == "Build Test Project"
        assert project.version == "1.0.0"
        assert project.assembler == "xa"
        assert project.main_file == "main.asm"

        # Check rebuild needed because output file does not exist
        assert is_rebuild_required(project) is True

    finally:
        if os.path.exists(test_yaml_path):
            os.remove(test_yaml_path)


# ============================================================================
# TASK 3.4 TESTS: VICE Harness
# ============================================================================

def test_vice_harness():
    """Verifies test harness execution controls, offline state simulation, and SIDState."""
    harness = VICEHarness(bin_path="nonexistent_x64sc")
    # Ensure offline mode loads correctly
    harness.start_emulator(headless=True)
    assert harness.process is None

    # Load PRG in simulated memory
    # Create mock 5-byte PRG
    mock_prg_path = "test_mock.prg"
    # First 2 bytes are address (e.g. 0x1000) followed by 3 bytes of data
    with open(mock_prg_path, "wb") as f:
        f.write(bytes([0x00, 0x10, 0xAA, 0xBB, 0xCC]))

    try:
        harness.load_prg(mock_prg_path)
        # Verify simulated memory load
        data = harness.read_memory(0x1000, 3)
        assert data == bytes([0xAA, 0xBB, 0xCC])
    finally:
        if os.path.exists(mock_prg_path):
            os.remove(mock_prg_path)

    # Keypress, screenshots, and run_until interfaces check
    harness.press_key("SPACE")
    assert harness.run_until(lambda: True, timeout_ms=500) is True

    screenshot = harness.get_screenshot()
    assert screenshot.size == (320, 200)

    # SIDState parsing
    sid_state = harness.get_sid_state()
    assert isinstance(sid_state, SIDState)
    assert sid_state.voice1_freq == 0

    harness.stop_emulator()
