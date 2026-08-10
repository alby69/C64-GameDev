# tests/test_invaders.py
import pytest
from c64kit.core.memory import C64Memory
from c64kit.core.constants import SCREEN_RAM, COLOR_RAM_BASE, VIC_BORDER, VIC_BG, VIC_RASTER, SID_RANDOM
from c64kit.core.utils import ascii_to_screen_code, screen_code_to_ascii, ascii_to_petscii
from c64kit.video.colors import Colors
from c64kit.video.vic import VICII
from c64kit.video.screen import Screen
from c64kit.video.charset import Charset
from c64kit.audio.sid import SID
from c64kit.audio.sfx import SoundEffects
from c64kit.input.joystick import Joystick
from c64kit.input.keyboard import Keyboard
from c64kit.game.sprite_data import GameData
from c64kit.game.score import ScoreManager
from c64kit.game.invaders import InvadersGame

def test_memory_flat_and_color_ram():
    mem = C64Memory()

    # Check general RAM write/read
    mem.write(0x1000, 42)
    assert mem.read(0x1000) == 42

    # Check Color RAM logical mapping ($D800 - $DBFF)
    mem.write(0xD800, 15)  # Write Light Grey
    assert mem.read(0xD800) == 15
    assert mem.color_ram[0] == 15

    # Color RAM is nibble-only (4-bit)
    mem.write(0xD801, 0xFF)
    assert mem.read(0xD801) == 0x0F  # Only lower 4 bits are preserved

    # Check write_color helper
    mem.write_color(10, Colors.GREEN)
    assert mem.read(0xD80A) == Colors.GREEN

def test_sid_random_noise_rng():
    mem = C64Memory()

    # Reading SID_RANDOM should produce varying pseudo-random bytes
    vals = {mem.read(SID_RANDOM) for _ in range(50)}
    assert len(vals) > 1  # Verify we generated different random numbers
    assert all(0 <= v <= 255 for v in vals)

def test_utils_conversion():
    # 'A'-'Z' -> 1-26
    assert ascii_to_screen_code('A') == 1
    assert ascii_to_screen_code('Z') == 26
    # '0'-'9' -> 48-57
    assert ascii_to_screen_code('0') == 48
    assert ascii_to_screen_code('9') == 57
    # Space -> 32 (0x20)
    assert ascii_to_screen_code(' ') == 0x20

    # Screen code to ascii
    assert screen_code_to_ascii(1) == 'A'
    assert screen_code_to_ascii(48) == '0'
    assert screen_code_to_ascii(0x20) == ' '

    # PETSCII conversion
    assert ascii_to_petscii('A') == 0x41
    assert ascii_to_petscii('a') == 0x41  # Auto-uppercase

def test_vic_ii_registers():
    mem = C64Memory()
    vic = VICII(mem)

    vic.set_border_color(Colors.RED)
    assert mem.read(VIC_BORDER) == Colors.RED

    vic.set_background_color(Colors.BLUE)
    assert mem.read(VIC_BG) == Colors.BLUE

    vic.set_charset_location(0x3800)
    # $3800 -> 14 -> value $1C or $1E depending on screen RAM location
    assert mem.read(0xD018) == 14

    # Raster line
    line = vic.get_raster_line()
    assert 0 <= line < 312

def test_screen_matrix_operations():
    mem = C64Memory()
    screen = Screen(mem)

    # Clear screen
    screen.clear(char=0x20, color=Colors.GREEN)
    assert mem.read(SCREEN_RAM) == 0x20
    assert mem.read(COLOR_RAM_BASE) == Colors.GREEN

    # Poke char
    screen.poke_char(5, 5, 1, Colors.WHITE)  # 'A' at (5,5)
    assert mem.read(SCREEN_RAM + 5 * 40 + 5) == 1
    assert mem.read(COLOR_RAM_BASE + 5 * 40 + 5) == Colors.WHITE

    # Poke string
    screen.poke_string(10, 10, "INVADERS", Colors.CYAN)
    for idx, char in enumerate("INVADERS"):
        offset = 10 * 40 + 10 + idx
        assert mem.read(SCREEN_RAM + offset) == ascii_to_screen_code(char)
        assert mem.read(COLOR_RAM_BASE + offset) == Colors.CYAN

def test_screen_draw_sprite():
    mem = C64Memory()
    screen = Screen(mem)

    # Draw Player Sprite (ID 0) at (0,0)
    screen.draw_sprite(0, 0, sprite_id=0, frame=0, color=Colors.GREEN)

    # Player base character data starts at offset 1 in SPRDATA_BASE
    expected_sprite = GameData.SPRDATA_BASE[1:16]
    for row in range(3):
        for col in range(5):
            char_in_mem = mem.read(SCREEN_RAM + row * 40 + col)
            assert char_in_mem == expected_sprite[row * 5 + col]

def test_screen_draw_bunker():
    mem = C64Memory()
    screen = Screen(mem)

    # Draw bunker using C64 address
    screen.draw_bunker(SCREEN_RAM, GameData.BUNKER_DATA)
    # Verify that first character $60 is placed at offset 1 from base SCREEN_RAM
    assert mem.read(SCREEN_RAM + 1) == 0x60

def test_charset_installation():
    mem = C64Memory()
    charset = Charset()

    charset.install_pet_charset(mem, 0x3800)
    # Check that $3800 + $300 ($3B00) contains PET custom graphics characters (such as first byte $FF)
    assert mem.read(0x3800 + 0x0300) == 0xFF

def test_sid_and_sfx():
    mem = C64Memory()
    sid = SID(mem)
    sfx = SoundEffects(sid)

    # Init checks
    assert mem.read(0xD418) == 0x0F  # Volume set

    # Play tone
    sid.play_tone(0x10, 0x01, 0x40, gate=True)
    assert mem.read(0xD400) == 0x10
    assert mem.read(0xD401) == 0x01
    assert mem.read(0xD404) == 0x41

    # Triggers Sound effects
    sfx.invader_step(step_counter=4)
    # FREQ_TABLE[4] is 0x50
    assert mem.read(0xD400) == 0x50

    sfx.player_shoot(shoot_timer=5)
    # FREQ_EFFECT[5] is 0x44
    assert mem.read(0xD400) == 0x44

def test_input_joystick_and_keyboard():
    mem = C64Memory()
    joy = Joystick(mem)
    kbd = Keyboard(mem)

    # Joystick state changes
    joy.set_state(left=True, right=False, fire=True)
    status = joy.read()
    assert status['left'] is True
    assert status['right'] is False
    assert status['fire'] is True
    assert joy.get_direction() == -1

    # Keyboard matrix press key
    kbd.press_key('A')
    assert mem.read(0xCB) == 10  # Matrix code of 'A'
    assert kbd.get_key() == ord('A')

    kbd.release_key()
    assert mem.read(0xCB) == 64

    # BSOUT test
    kbd.bsout(0x41)  # 'A'
    kbd.bsout(0x93)  # CLR
    assert kbd.get_output() == "A[CLR]"

def test_score_bcd_manager():
    mem = C64Memory()
    screen = Screen(mem)
    sm = ScoreManager(mem, screen)

    # Test BCD conversion helper
    assert sm._int_to_bcd(1234) == (0x34, 0x12)
    assert sm._bcd_to_int(0x34, 0x12) == 1234

    # Test get/set score
    sm.set_score(1500)
    assert sm.get_score() == 1500
    assert mem.read(0x033C) == 0x00
    assert mem.read(0x033D) == 0x15

    # Test add score
    sm.add_score(250)
    assert sm.get_score() == 1750

    # High score should update automatically
    assert sm.get_high_score() == 1750

    # Set lives and draw
    sm.set_lives(4)
    assert sm.get_lives() == 4
    sm.draw_lives()
    # Check that 4 life icons (char 0x6C) are printed at offset 30-33 on HUD
    for col in range(4):
        assert mem.read(SCREEN_RAM + 30 + col) == 0x6C

def test_invaders_game_orchestrator():
    game = InvadersGame(headless=True)

    # Boot sequence
    game.boot_sequence()
    # Border & Bg should be Black
    assert game.mem.read(VIC_BORDER) == Colors.BLACK
    assert game.mem.read(VIC_BG) == Colors.BLACK
    # "How to get sound" should be copied to Screen RAM
    assert game.mem.read(SCREEN_RAM + 3) == ascii_to_screen_code('*')

    # Menu screen loading
    game.load_menu()
    # "SPACE INVADERS" printed at row 8
    assert game.mem.read(SCREEN_RAM + 8 * 40 + 11) == ascii_to_screen_code('S')

    # Start game
    game.start_game()
    assert game.game_started is True
    assert game.score.get_score() == 0
    assert game.score.get_lives() == 3
    # Check that bunkers are drawn
    assert game.mem.read(0x06FF + 1) == 0x60
    # Check that player base is spawned at (20, 21)
    # Expected base sprite data starts at SPRDATA_BASE + 1
    assert game.mem.read(SCREEN_RAM + 21 * 40 + 20) == GameData.SPRDATA_BASE[1]
