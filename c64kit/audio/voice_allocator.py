# c64kit/audio/voice_allocator.py
from typing import Dict, Any, List, Optional

class VoiceState:
    """Tracks state and lifecycle of a registered voice allocation."""

    def __init__(self, voice_idx: int):
        self.voice_idx = voice_idx
        self.busy = False
        self.priority = 0
        self.tag: Optional[str] = None
        self.age = 0


class VoiceAllocator:
    """
    Manages allocation and steal logic for the 3 C64 SID voice channels.
    Supports priority allocation, oldest-voice stealing, and allocation tracking.
    """

    def __init__(self):
        self.voices = [VoiceState(i) for i in range(3)]

    def allocate(self, priority: int = 1, tag: Optional[str] = None) -> int:
        """
        Allocates an available SID voice channel.
        If all voices are occupied, steal the voice with the lowest priority.
        In case of a priority tie, steal the oldest voice (round-robin priority fallback).
        """
        # 1. Look for a free voice
        for v in self.voices:
            if not v.busy:
                v.busy = True
                v.priority = priority
                v.tag = tag
                v.age = 0
                return v.voice_idx

        # 2. Steal voice if none is free
        # Sort by priority ascending, then age descending (oldest first)
        best_steal_candidate = min(
            self.voices,
            key=lambda x: (x.priority, -x.age)
        )

        best_steal_candidate.busy = True
        best_steal_candidate.priority = priority
        best_steal_candidate.tag = tag
        best_steal_candidate.age = 0
        return best_steal_candidate.voice_idx

    def release(self, voice_idx: int) -> None:
        """Releases the target voice channel."""
        if 0 <= voice_idx < 3:
            v = self.voices[voice_idx]
            v.busy = False
            v.priority = 0
            v.tag = None
            v.age = 0

    def tick(self) -> None:
        """Ticks the allocator, incrementing the age of active voice tracks."""
        for v in self.voices:
            if v.busy:
                v.age += 1
