"""c64kit/tools/sid_compiler.py

Compiler to translate YAML/JSON sound effects (SFX) and music pattern definitions
into structured 6502 assembly files (.asm) or binary formats (.bin).
"""

import os
import json
import argparse
from typing import List, Dict, Any, Tuple, Union

# Try importing yaml, fallback to json only if not installed
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

__all__ = [
    "note_to_sid_freq",
    "waveform_to_byte",
    "compile_sfx_to_asm",
    "compile_music_to_asm",
    "compile_sound_config",
]

# Note name offset from A
NOTE_OFFSETS = {
    'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5,
    'F': -4, 'F#': -3, 'G': -2, 'G#': -1, 'A': 0,
    'A#': 1, 'B': 2
}


def note_to_sid_freq(note_str: str) -> int:
    """Converts a standard note string (e.g., 'C-3', 'A#-4', 'F-5') to a 16-bit C64 SID frequency.

    Formula:
        f = 440 * 2^((semitones_from_A4) / 12)
        sid_freq = int(f * 17.0284) (for PAL C64)

    Args:
        note_str: String representation of note.

    Returns:
        16-bit integer SID frequency value (0-65535).
    """
    if note_str == "..." or note_str == "---" or not note_str:
        return 0

    try:
        # Expected format: C-3, D#-4, G#5, etc.
        note_str = note_str.strip().upper()
        if '-' in note_str:
            name, oct_str = note_str.split('-')
        else:
            # find where number starts
            idx = 0
            while idx < len(note_str) and not note_str[idx].isdigit():
                idx += 1
            name = note_str[:idx]
            oct_str = note_str[idx:]

        octave = int(oct_str)
        offset = NOTE_OFFSETS[name]

        # Semitones from A-4
        semitones = (octave - 4) * 12 + offset
        freq_hz = 440.0 * (2.0 ** (semitones / 12.0))

        # SID PAL frequency constant
        sid_freq = int(freq_hz * 17.0284)
        return min(max(sid_freq, 0), 65535)
    except Exception:
        return 0


def waveform_to_byte(waveform: Union[str, List[str]]) -> int:
    """Converts a waveform name or list of names to the C64 SID control register byte value.

    Bits:
        Bit 7: Noise ($80)
        Bit 6: Pulse ($40)
        Bit 5: Sawtooth ($20)
        Bit 4: Triangle ($10)

    Args:
        waveform: Waveform name(s) such as 'noise', 'sawtooth', 'triangle', 'pulse'.

    Returns:
        The matched control register byte value.
    """
    if isinstance(waveform, list):
        val = 0
        for wf in waveform:
            val |= waveform_to_byte(wf)
        return val

    wf_str = str(waveform).lower().strip()
    if "noise" in wf_str:
        return 0x80
    elif "pulse" in wf_str:
        return 0x40
    elif "sawtooth" in wf_str or "saw" in wf_str:
        return 0x20
    elif "triangle" in wf_str or "tri" in wf_str:
        return 0x10
    return 0x00


def compile_sfx_to_asm(sfx_dict: Dict[str, Any]) -> Tuple[str, List[str]]:
    """Compiles a dictionary of sound effects to a structured 6502 assembly block.

    Args:
        sfx_dict: SFX configurations dictionary.

    Returns:
        A tuple of (SFX_TABLE assembly string, list of individual SFX assembly strings).
    """
    table_lines = []
    table_lines.append("; ============================================================================")
    table_lines.append("; SOUND EFFECTS TABLE")
    table_lines.append("; ============================================================================")
    table_lines.append("SFX_TABLE:")

    sfx_blocks = []

    for name, config in sfx_dict.items():
        table_lines.append(f"    .word sfx_{name}")

        sfx_lines = []
        sfx_lines.append(f"; SFX: {name}")
        sfx_lines.append(f"sfx_{name}:")

        # Parse basic parameters
        waveform = waveform_to_byte(config.get("waveform", "noise"))
        attack = int(config.get("attack", 0)) & 0x0F
        decay = int(config.get("decay", 0)) & 0x0F
        sustain = int(config.get("sustain", 0)) & 0x0F
        release = int(config.get("release", 0)) & 0x0F

        ad_byte = (attack << 4) | decay
        sr_byte = (sustain << 4) | release

        # Frequency start and end
        freq_start = config.get("freq_start", 4000)
        freq_end = config.get("freq_end", 1000)
        if isinstance(freq_start, str):
            freq_start = note_to_sid_freq(freq_start)
        if isinstance(freq_end, str):
            freq_end = note_to_sid_freq(freq_end)

        freq_start_lo = freq_start & 0xFF
        freq_start_hi = (freq_start >> 8) & 0xFF
        freq_end_lo = freq_end & 0xFF
        freq_end_hi = (freq_end >> 8) & 0xFF

        # Duration in frames (assuming 50Hz PAL)
        duration_ms = config.get("duration_ms", 100)
        duration_frames = max(1, int(duration_ms / 20))

        # Filter settings
        filter_cfg = config.get("filter", {})
        filter_mode_val = 0
        if filter_cfg:
            mode = str(filter_cfg.get("mode", "")).lower()
            if "low" in mode:
                filter_mode_val = 0x10
            elif "band" in mode:
                filter_mode_val = 0x20
            elif "high" in mode:
                filter_mode_val = 0x40

            resonance = int(filter_cfg.get("resonance", 0)) & 0x0F
            filter_mode_val |= (resonance << 4)

            co_start = filter_cfg.get("cutoff_start", 0)
            co_end = filter_cfg.get("cutoff_end", 0)
        else:
            co_start = 0
            co_end = 0

        # Assembly lines construction
        sfx_lines.append(f"    .byte ${waveform:02x}          ; Waveform Control")
        sfx_lines.append(f"    .byte ${ad_byte:02x}          ; Attack / Decay")
        sfx_lines.append(f"    .byte ${sr_byte:02x}          ; Sustain / Release")
        sfx_lines.append(f"    .byte ${freq_start_lo:02x}, ${freq_start_hi:02x}    ; Freq Start (16-bit)")
        sfx_lines.append(f"    .byte ${freq_end_lo:02x}, ${freq_end_hi:02x}    ; Freq End (16-bit)")
        sfx_lines.append(f"    .byte ${duration_frames:02x}          ; Duration in PAL frames")
        sfx_lines.append(f"    .byte ${filter_mode_val:02x}          ; Filter Mode & Resonance")
        sfx_lines.append(f"    .byte {co_start & 0xFF}, {(co_start >> 8) & 0xFF}  ; Filter Cutoff Start")
        sfx_lines.append(f"    .byte {co_end & 0xFF}, {(co_end >> 8) & 0xFF}  ; Filter Cutoff End")
        sfx_lines.append("")

        sfx_blocks.append("\n".join(sfx_lines))

    # Terminator or count marker
    table_lines.append("    .word 0             ; Table Terminator")
    table_lines.append("")

    return "\n".join(table_lines), sfx_blocks


def compile_music_to_asm(music_dict: Dict[str, Any]) -> str:
    """Compiles music tracks and patterns to a structured 6502 assembly block.

    Args:
        music_dict: Music definitions dictionary containing BPM and patterns.

    Returns:
        An assembly string representing the music patterns.
    """
    lines = []
    lines.append("; ============================================================================")
    lines.append("; MUSIC TRACKS & PATTERNS")
    lines.append("; ============================================================================")

    bpm = music_dict.get("bpm", 120)
    # 50Hz PAL ticks per beat = 50 * 60 / BPM
    ticks_per_beat = int((50.0 * 60.0) / bpm) if bpm > 0 else 25

    lines.append(f"MUSIC_BPM = {bpm}")
    lines.append(f"MUSIC_TICKS_PER_BEAT = {ticks_per_beat}")
    lines.append("")

    patterns = music_dict.get("patterns", [])
    for idx, pat in enumerate(patterns):
        lines.append(f"music_pattern_{idx}:")
        # Format list: [note, instrument, effect] or similar
        for step in pat:
            if isinstance(step, list) and len(step) >= 1:
                note_name = step[0]
                freq = note_to_sid_freq(note_name)
                freq_lo = freq & 0xFF
                freq_hi = (freq >> 8) & 0xFF

                inst_id = int(step[1]) if len(step) > 1 else 0
                effect_id = int(step[2]) if len(step) > 2 else 0

                lines.append(f"    .byte ${freq_lo:02x}, ${freq_hi:02x}, ${inst_id:02x}, ${effect_id:02x}  ; Note {note_name}")
            else:
                lines.append("    .byte $00, $00, $00, $00")

        lines.append("    .byte $ff, $ff, $ff, $ff  ; End of pattern")
        lines.append("")

    return "\n".join(lines)


def compile_sound_config(config: Dict[str, Any]) -> str:
    """Compiles both SFX and music definitions into a cohesive assembly string.

    Args:
        config: The entire sound YAML or JSON structure.

    Returns:
        The complete 6502 assembly string.
    """
    sections = []
    sections.append("; ============================================================================")
    sections.append("; GENERATED C64 SID SOUND CONSTRUCTIONS")
    sections.append("; ============================================================================")
    sections.append("")

    # SFX
    if "sfx" in config:
        table_asm, sfx_asms = compile_sfx_to_asm(config["sfx"])
        sections.append(table_asm)
        for block in sfx_asms:
            sections.append(block)

    # Music
    if "music" in config:
        music_asm = compile_music_to_asm(config["music"])
        sections.append(music_asm)

    return "\n".join(sections)


def main() -> None:
    """Main execution entry point for CLI."""
    parser = argparse.ArgumentParser(description="Compile YAML/JSON SFX and music definitions to 6502 assembly.")
    parser.add_argument("--input", required=True, help="Input sound configuration file (YAML or JSON)")
    parser.add_argument("--output", required=True, help="Output assembly filename (.asm)")

    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' does not exist.")
        return

    # Try YAML first if available, fallback to JSON
    config = {}
    with open(args.input, "r", encoding="utf-8") as f:
        if args.input.endswith((".yaml", ".yml")):
            if HAS_YAML:
                config = yaml.safe_load(f)
            else:
                print("Error: PyYAML not installed but input is a YAML file.")
                return
        else:
            config = json.load(f)

    # Compile
    asm_output = compile_sound_config(config)

    # Write output
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(asm_output)

    print(f"Successfully compiled '{args.input}' to '{args.output}'")


if __name__ == "__main__":
    main()
