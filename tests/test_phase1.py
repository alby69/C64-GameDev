# tests/test_phase1.py
import pytest
from c64kit.core.memory import C64Memory
from c64kit.core.cia import CIA1, CIA2
from c64kit.core.interrupts import InterruptManager
from c64kit.video.vic import VICII
from c64kit.video.sprites import Sprites
from c64kit.video.scroll import Scroll
from c64kit.audio.sid import SID
from c64kit.audio.voice_allocator import VoiceAllocator
from c64kit.audio.music_player import MusicPlayer
from c64kit.input.joystick import Joystick
from c64kit.input.keyboard import Keyboard
from c64kit.input.input_manager import InputManager

def test_memory_banking_config():
    """Verifies that RAM/ROM/IO banking maps correctly based on processor port $01."""
    mem = C64Memory()

    # Fill BASIC ROM region in ROM with dummy values to distinguish it from RAM
    mem.basic_rom[0] = 0xAA
    mem.ram[0xA000] = 0x55

    # Default configuration: LORAM=1, HIRAM=1, CHAREN=1 ($01 = $37)
    # Both LORAM and HIRAM 1 means BASIC ROM is mapped at $A000-$BFFF for reading.
    assert mem.read(0xA000) == 0xAA

    # Writing to a ROM-mapped address writes through to the underlying RAM on a C64.
    mem.write(0xA000, 0x11)
    assert mem.read(0xA000) == 0xAA  # Still reads ROM
    assert mem.ram[0xA000] == 0x11   # RAM holds written value

    # Switch off LORAM: LORAM=0 ($01 = $36) -> RAM at $A000-$BFFF is mapped
    mem.write(0x0001, 0x36)
    assert mem.read(0xA000) == 0x11  # Reads underlying RAM now!

def test_cia_timer_down_counting():
    """Verifies that CIA timer counts down and generates interrupts correctly."""
    cia = CIA1()

    # Load latch value 10 to Timer A
    cia.write(0x04, 10 & 0xFF)
    cia.write(0x05, (10 >> 8) & 0xFF)

    # Enable Timer A interrupt in ICR
    # Writing $81 sets mask bit 0 (Timer A)
    cia.write(0x0D, 0x81)

    # Start Timer A (CRA bit 0 = 1)
    cia.write(0x0E, 0x01)

    assert cia.timer_a_running is True

    # Tick 5 cycles
    triggered = cia.tick(5)
    assert triggered is False
    assert cia.timer_a == 5

    # Tick another 5 cycles -> should underflow!
    triggered = cia.tick(5)
    assert triggered is True
    # Timer A should reload from latch (10)
    assert cia.timer_a == 10
    # Reading ICR should show active interrupt and reset active status
    icr = cia.read(0x0D)
    assert (icr & 0x01) != 0  # Underflow flag active
    assert (icr & 0x80) != 0  # Interrupt pending flag active

    # Verify ICR read cleared status
    assert cia.read(0x0D) == 0x00

def test_sprite_control_and_collision():
    """Verifies VIC-II sprite controls, pointers, and AABB collision detection."""
    mem = C64Memory()
    vic = VICII(mem)
    sprites = Sprites(mem)

    # Enable sprite 0 and sprite 1
    vic.enable_sprite(0, True)
    vic.enable_sprite(1, True)

    assert vic.is_sprite_enabled(0) is True
    assert vic.is_sprite_enabled(1) is True

    # Position sprite 0 at (100, 150)
    vic.set_sprite_position(0, 100, 150)
    # Position sprite 1 at (110, 160) -> Overlaps (width 24, height 21)
    vic.set_sprite_position(1, 110, 160)

    # Check position readings
    assert vic.get_sprite_position(0) == (100, 150)
    assert vic.get_sprite_position(1) == (110, 160)

    # Check collisions
    assert sprites.check_collision(0, 1) is True

    # Move sprite 1 far away -> no longer colliding
    vic.set_sprite_position(1, 200, 150)
    assert sprites.check_collision(0, 1) is False

def test_sid_multivoice_and_adsr():
    """Verifies SID multiple voice settings and ADSR configuration registers."""
    mem = C64Memory()
    sid = SID(mem)

    # Configure ADSR for Voice 2
    # Attack=1, Decay=2, Sustain=15, Release=8
    sid.set_adsr_voice(1, 1, 2, 15, 8)

    # Trigger tone on Voice 2
    sid.play_tone_voice(1, 0x20, 0x10, 0x20, True)  # Sawtooth wave + Gate on

    voice2 = sid.voices[1]
    assert voice2.attack == 1
    assert voice2.decay == 2
    assert voice2.sustain == 15
    assert voice2.release == 8
    assert voice2.freq_lo == 0x20
    assert voice2.freq_hi == 0x10
    assert (voice2.control & 0x21) == 0x21  # Sawtooth (0x20) and Gate (0x01)

def test_keyboard_scanning_and_input_manager():
    """Verifies keyboard matrix scanning simulation and the InputManager layer."""
    mem = C64Memory()
    joy = Joystick(mem)
    kbd = Keyboard(mem)
    mgr = InputManager(joy, kbd)

    # Bind action "JUMP" to keyboard 'A' and Joystick 2 UP button
    mgr.bind_action("JUMP", ["A", "JOY2_UP"])

    # Initial state: not held or pressed
    mgr.update()
    assert mgr.is_held("JUMP") is False
    assert mgr.is_pressed("JUMP") is False

    # Programmatically press key 'A'
    kbd.press_key('A')
    mgr.update()

    # Matrix code check
    assert mem.read(0xCB) == 10  # code of 'A'

    # Action state check: 'A' is bound, so JUMP should transition to pressed and held
    assert mgr.is_held("JUMP") is True
    assert mgr.is_pressed("JUMP") is True

    # Next frame update: still held, but pressed becomes False
    mgr.update()
    assert mgr.is_held("JUMP") is True
    assert mgr.is_pressed("JUMP") is False

    # Release key
    kbd.release_key()
    mgr.update()
    assert mgr.is_held("JUMP") is False
    assert mgr.is_released("JUMP") is True
