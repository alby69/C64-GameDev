# c64kit/game/invaders.py
import pygame
import sys
from ..core.memory import C64Memory
from ..core.constants import SCREEN_RAM, COLOR_RAM_BASE, SYSTEM_TYPE
from ..video.colors import Colors
from ..video.vic import VICII
from ..video.screen import Screen
from ..video.charset import Charset
from ..audio.sid import SID
from ..audio.sfx import SoundEffects
from ..input.joystick import Joystick
from ..input.keyboard import Keyboard
from .score import ScoreManager
from .sprite_data import GameData

class InvadersGame:
    """
    Main Space Invaders Game class.
    Orchestrates memory, video, audio, input, scoring, and level logic.
    Replicates original C64 Space Invaders boot, menu, and gameloop structure.
    """

    def __init__(self, headless: bool = True):
        self.headless = headless
        self.mem = C64Memory()
        self.vic = VICII(self.mem)
        self.screen = Screen(self.mem)
        self.sid = SID(self.mem)
        self.sfx = SoundEffects(self.sid)
        self.joystick = Joystick(self.mem)
        self.keyboard = Keyboard(self.mem)
        self.score = ScoreManager(self.mem, self.screen)
        self.charset = Charset()

        # Game state variables
        self.game_started = False
        self.game_over = False
        self.ufo_timer = 0
        self.invaders_list = []
        self.player_x = 20  # logical column index (starts in center)

        # Initialize C64 system variables in Page 2
        self.mem.write(SYSTEM_TYPE, 0)  # 0 = PAL, 1 = NTSC

    def boot_sequence(self) -> None:
        """
        ASM: START — $080E
        1. Set border and background color to black
        2. Install custom PET graphics charset at $3800
        3. Initialize SID sound engine
        4. Copy screen RAM "How to get sound" and clear color RAM
        """
        self.vic.set_border_color(Colors.BLACK)
        self.vic.set_background_color(Colors.BLACK)
        self.charset.install_pet_charset(self.mem, 0x3800)
        self.sid.init()

        # Fill screen matrix and setup colors
        self.screen.clear(0x20, Colors.GREEN)
        # White HUD top row
        for col in range(40):
            self.screen.poke_char(col, 0, 0x20, Colors.WHITE)

        # Copy "How to get sound" data to Screen RAM
        for idx, byte in enumerate(GameData.SCRD1C00_DATA):
            self.mem.write(SCREEN_RAM + idx, byte)

    def load_menu(self) -> None:
        """Loads and displays the game main menu screen in Screen memory."""
        self.screen.clear(0x20, Colors.GREEN)
        for col in range(40):
            self.screen.poke_char(col, 0, 0x20, Colors.WHITE)

        # Draw Title and Menu Text
        # "SCORE" text at top (HUD)
        self.screen.poke_string(1, 0, "SCORE", Colors.WHITE)
        self.screen.poke_string(10, 0, "HIGH", Colors.WHITE)

        # Menu content
        self.screen.poke_string(11, 8, "SPACE INVADERS", Colors.GREEN)
        self.screen.poke_string(6, 12, "PUSH ANY KEY TO START", Colors.WHITE)
        self.screen.poke_string(14, 16, "PLAY BASE: A/D", Colors.GREEN)
        self.screen.poke_string(15, 18, "FIRE: SPACE/J", Colors.GREEN)

    def start_game(self) -> None:
        """
        Initializes game state, draws bunkers, BCD scores HUD, lives,
        and spawns invaders based on SCRD1000_DATA.
        """
        self.game_started = True
        self.game_over = False
        self.score.reset()
        self.screen.clear(0x20, Colors.GREEN)

        # White HUD row
        for col in range(40):
            self.screen.poke_char(col, 0, 0x20, Colors.WHITE)

        # Update HUD text
        self.screen.poke_string(1, 0, "SCORE", Colors.WHITE)
        self.screen.poke_string(10, 0, "HIGH", Colors.WHITE)

        # Draw bunkers (L0D60 base addresses)
        bunker_bases = [0x06FF, 0x0706, 0x070E, 0x0715]
        for base in bunker_bases:
            self.screen.draw_bunker(base, GameData.BUNKER_DATA)

        # Draw player base initial position
        self.player_x = 20
        self.screen.draw_sprite(self.player_x, 21, sprite_id=0, color=Colors.GREEN)

        # Initialize invaders list
        self.invaders_list = []
        # SCRD1000_DATA contains positions as low, high address pairs (40 byte pairs)
        # Followed by 48 bytes of invader types
        scrd1000 = GameData.SCRD1000_DATA
        for i in range(40):
            low = scrd1000[2*i]
            high = scrd1000[2*i + 1]
            addr = (high << 8) | low
            # Offset mapping from SCREEN_RAM
            offset = addr - SCREEN_RAM
            y = offset // 40
            x = offset % 40
            invader_type = scrd1000[80 + i] if (80 + i) < len(scrd1000) else 1
            self.invaders_list.append({
                'x': x,
                'y': y,
                'type': invader_type,
                'alive': True
            })

        # Draw initial invaders
        self.draw_invaders()

        # Update scores display
        self.score.draw_score()
        self.score.draw_high_score()
        self.score.draw_lives()

    def draw_invaders(self) -> None:
        """Draws all active invaders onto screen memory."""
        for invader in self.invaders_list:
            if invader['alive']:
                # Draw the corresponding sprite (invader type 1, 2, 3)
                self.screen.draw_sprite(invader['x'], invader['y'], invader['type'], frame=0, color=Colors.GREEN)

    def trigger_game_over(self) -> None:
        """Displays GAME OVER overlay on screen."""
        self.game_over = True
        self.screen.poke_string(15, 12, "GAME OVER", Colors.RED)

    def run_pygame_window(self) -> None:
        """
        Runs an interactive Pygame graphical display.
        This provides visual verification and interactive gameplay!
        """
        if self.headless:
            return

        pygame.init()
        # Scale screen 400x300 (C64 logic resolution 320x200 padded)
        # Let's map each C64 Character cell (40x25) to 16x16 pixels -> 640x400 window!
        cell_size = 16
        win_w, win_h = 40*cell_size, 25*cell_size
        screen_surf = pygame.display.set_mode((win_w, win_h))
        pygame.display.set_caption("Space Invaders C64 - Python Emulated")
        clock = pygame.time.Clock()

        self.boot_sequence()
        menu_loaded = False
        game_playing = False

        while True:
            # Event processing
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
                elif event.type == pygame.KEYDOWN:
                    if not menu_loaded:
                        # Move to menu
                        self.load_menu()
                        menu_loaded = True
                    elif not game_playing:
                        # Start game
                        self.start_game()
                        game_playing = True
                    else:
                        # Game keys
                        if event.key == pygame.K_p:
                            # Toggle Pause (Write to $CB key code 15)
                            self.keyboard.press_key('P')
                        elif event.key == pygame.K_F1:
                            # Quick Restart (Write to $CB key code 4)
                            self.keyboard.press_key('F1')
                            self.start_game()

            # Handle interactive player movement & shooting
            if game_playing and not self.game_over:
                keys = pygame.key.get_pressed()
                left_pressed = keys[pygame.K_a] or keys[pygame.K_LEFT]
                right_pressed = keys[pygame.K_d] or keys[pygame.K_RIGHT]
                fire_pressed = keys[pygame.K_SPACE] or keys[pygame.K_j]

                # Update joystick hardware registers
                self.joystick.set_state(left_pressed, right_pressed, fire_pressed)

                # Process movement logic (mimics L058D assembly structure)
                direction = self.joystick.get_direction()
                old_x = self.player_x
                if direction == -1 and self.player_x > 1:
                    self.player_x -= 1
                elif direction == 1 and self.player_x < 34:
                    self.player_x += 1

                if old_x != self.player_x:
                    # Erase old sprite position & draw at new
                    self.screen.poke_string(old_x, 21, "     ", Colors.GREEN)
                    self.screen.draw_sprite(self.player_x, 21, sprite_id=0, color=Colors.GREEN)

                if fire_pressed:
                    # Trigger sound
                    self.sfx.player_shoot(shoot_timer=10)
                    # Simple scoring mockup
                    self.score.add_score(10)
                    self.score.draw_score()

            # Render Screen RAM buffer to Pygame Window
            screen_surf.fill((0, 0, 0)) # Background
            for y in range(25):
                for x in range(40):
                    char_code = self.mem.read(SCREEN_RAM + (y * 40 + x))
                    color_code = self.mem.color_ram[(y * 40 + x)] & 0x0F
                    rgb = Colors.RGB_PALETTE.get(color_code, (255, 255, 255))

                    # Render character cell
                    # If it's standard ASCII/text
                    if 32 <= char_code < 127:
                        # Fallback simple text rendering
                        font = pygame.font.SysFont("monospace", 14, bold=True)
                        txt = font.render(chr(char_code), True, rgb)
                        screen_surf.blit(txt, (x * cell_size + 2, y * cell_size))
                    else:
                        # Custom PET graphics tiles (e.g. bunker 0x60, sprite bits)
                        # We draw solid boxes or custom graphics patterns based on charset data
                        rect = pygame.Rect(x * cell_size, y * cell_size, cell_size, cell_size)
                        if char_code == 0x60:  # Full block bunker
                            pygame.draw.rect(screen_surf, rgb, rect)
                        elif char_code != 0x20:
                            # Simplistic pattern draw or generic block
                            pygame.draw.rect(screen_surf, rgb, rect.inflate(-4, -4), 1)

            pygame.display.flip()
            clock.tick(30)
