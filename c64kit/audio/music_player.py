# c64kit/audio/music_player.py
from typing import Dict, Any, List, Optional
from .sid import SID
from .voice_allocator import VoiceAllocator

# Map of note names to standard C64 SID frequency values (using PAL standard values)
NOTE_FREQS = {
    'C-3': 0x112F, 'C#3': 0x1236, 'D-3': 0x134F, 'D#3': 0x1479, 'E-3': 0x15B5, 'F-3': 0x1704,
    'F#3': 0x1867, 'G-3': 0x19DE, 'G#3': 0x1B6B, 'A-3': 0x1D0F, 'A#3': 0x1ECB, 'B-3': 0x20A0,
    'C-4': 0x225E, 'C#4': 0x246C, 'D-4': 0x269F, 'D#4': 0x28F2, 'E-4': 0x2B6B, 'F-4': 0x2E09,
    'F#4': 0x30CE, 'G-4': 0x33BC, 'G#4': 0x36D6, 'A-4': 0x3A1F, 'A#4': 0x3D97, 'B-4': 0x4140,
    'C-5': 0x44BD, 'C#5': 0x48D9, 'D-5': 0x4D3F, 'D#5': 0x51E5, 'E-5': 0x56D6, 'F-5': 0x5C12,
    'F#5': 0x619D, 'G-5': 0x6779, 'G#5': 0x6DAC, 'A-5': 0x743E, 'A#5': 0x7B2F, 'B-5': 0x8281,
}

class MusicPlayer:
    """
    Pattern-based tracker style music player for the C64 SID chip.
    Supports BPM configuration, note sequences, custom instruments, and looping.
    """

    def __init__(self, sid: SID, allocator: VoiceAllocator):
        self.sid = sid
        self.allocator = allocator
        self.bpm = 120
        self.playing = False
        self.current_pattern = 0
        self.current_row = 0
        self.patterns: List[List[List[Optional[str]]]] = []  # List of patterns, each has 32/64 rows, each has 3 voices
        self.instruments: Dict[str, Dict[str, int]] = {}
        self.loop_pattern = 0
        self.tick_counter = 0

    def set_bpm(self, bpm: int) -> None:
        """Sets target BPM."""
        self.bpm = max(1, bpm)

    def load_song(self, song_data: Dict[str, Any]) -> None:
        """Loads tracker-style patterns and instrument mappings from a song data dictionary."""
        self.patterns = song_data.get('patterns', [])
        self.instruments = song_data.get('instruments', {})
        self.loop_pattern = song_data.get('loop_pattern', 0)
        self.bpm = song_data.get('bpm', 120)
        self.current_pattern = 0
        self.current_row = 0
        self.tick_counter = 0

    def play(self) -> None:
        """Starts song playback."""
        self.playing = True

    def stop(self) -> None:
        """Stops song playback and turns off all gates."""
        self.playing = False
        for i in range(3):
            self.sid.play_tone_voice(i, 0, 0, 0, False)
            self.allocator.release(i)

    def tick(self) -> None:
        """
        Progresses the player track state based on active speed and ticks the SID voices.
        Should be called at a standard timer interval (e.g., 50Hz interrupt).
        """
        if not self.playing or not self.patterns:
            return

        # Simple tick speed divider based on BPM:
        # e.g., 120 BPM on 50Hz requires 1 step roughly every 6-7 ticks.
        step_divider = int(3000 / self.bpm)
        self.tick_counter += 1

        if self.tick_counter >= step_divider:
            self.tick_counter = 0
            self._play_row()

    def _play_row(self) -> None:
        """Processes and plays a single tracker row across active voices."""
        if self.current_pattern >= len(self.patterns):
            self.current_pattern = self.loop_pattern
            if not self.patterns:
                return

        pattern = self.patterns[self.current_pattern]
        if self.current_row >= len(pattern):
            self.current_row = 0
            self.current_pattern += 1
            if self.current_pattern >= len(self.patterns):
                self.current_pattern = self.loop_pattern
            pattern = self.patterns[self.current_pattern]

        row = pattern[self.current_row]
        for voice_idx, note_cmd in enumerate(row):
            if note_cmd:
                if note_cmd == 'OFF':
                    # Turn off voice gate
                    self.sid.play_tone_voice(voice_idx, 0, 0, 0, False)
                    self.allocator.release(voice_idx)
                elif note_cmd in NOTE_FREQS:
                    freq = NOTE_FREQS[note_cmd]
                    freq_lo = freq & 0xFF
                    freq_hi = (freq >> 8) & 0xFF

                    # Apply default ADSR/Instrument values or custom
                    inst = self.instruments.get(f'voice_{voice_idx}', {
                        'attack': 0, 'decay': 8, 'sustain': 10, 'release': 8, 'waveform': 0x10  # Triangle
                    })

                    self.sid.set_adsr_voice(
                        voice_idx,
                        inst.get('attack', 0),
                        inst.get('decay', 8),
                        inst.get('sustain', 10),
                        inst.get('release', 8)
                    )

                    # Trigger voice play
                    self.sid.play_tone_voice(
                        voice_idx,
                        freq_lo,
                        freq_hi,
                        inst.get('waveform', 0x10),
                        gate=True
                    )

        self.current_row += 1
