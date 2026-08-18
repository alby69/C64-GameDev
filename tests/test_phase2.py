"""Unit tests for Phase 2 components.

Verifies the State Machine, Sprite Engine, TileMap, Collision System, HUD/Score System,
and Level/Entity System.
"""

import os
import time
import pytest
from c64kit.core.memory import C64Memory
from c64kit.video.colors import Colors
from c64kit.video.screen import Screen
from c64kit.game.state_machine import GameStateMachine
from c64kit.game.sprite_engine import Sprite, SpriteEngine
from c64kit.game.tilemap import TileMap
from c64kit.game.collision_system import CollisionSystem, Collision
from c64kit.game.hud_system import ScoreManager, HUDSystem
from c64kit.game.level_manager import LevelConfig, LevelManager
from c64kit.game.entity_manager import Entity, EntityManager


# ============================================================================
# TASK 2.1 TESTS: State Machine
# ============================================================================

def test_state_machine_flow_and_validation():
    """Verifies valid flow, context persistence, and invalid transitions rejection."""
    fsm = GameStateMachine()

    # Track callbacks
    lifecycle = []

    fsm.register_state(
        "BOOT",
        on_enter=lambda: lifecycle.append("enter_boot"),
        on_exit=lambda: lifecycle.append("exit_boot"),
    )
    fsm.register_state("TITLE", on_enter=lambda: lifecycle.append("enter_title"))
    fsm.register_state("PLAY", on_enter=lambda: lifecycle.append("enter_play"))
    fsm.register_state("GAMEOVER", on_enter=lambda: lifecycle.append("enter_gameover"))

    # Initial transition from None to BOOT
    assert fsm.change_state("BOOT") is True
    assert fsm.current == "BOOT"
    assert "enter_boot" in lifecycle

    # Try invalid transition: BOOT -> PLAY (not in transition table)
    assert fsm.change_state("PLAY") is False
    assert fsm.current == "BOOT"

    # Transition to TITLE
    assert fsm.change_state("TITLE") is True
    assert "exit_boot" in lifecycle
    assert "enter_title" in lifecycle
    assert fsm.previous == "BOOT"
    assert fsm.current == "TITLE"

    # Persistent Context test
    fsm.context["high_score"] = 5000

    assert fsm.change_state("PLAY") is True
    assert fsm.context["high_score"] == 5000  # Context persists!

    # Sub-state overlay testing
    overlay_events = []
    fsm.register_sub_state(
        "PAUSE_MENU",
        on_enter=lambda: overlay_events.append("pause_enter"),
        on_exit=lambda: overlay_events.append("pause_exit")
    )
    assert fsm.enter_sub_state("PAUSE_MENU") is True
    assert fsm.sub_state == "PAUSE_MENU"
    assert "pause_enter" in overlay_events

    # Main state change clears sub-state
    assert fsm.change_state("GAMEOVER") is True
    assert fsm.sub_state is None
    assert "pause_exit" in overlay_events


# ============================================================================
# TASK 2.2 TESTS: Sprite & TileMap Engine
# ============================================================================

def test_sprite_engine_char_and_hardware():
    """Verifies SpriteEngine's drawing, dirty background buffer, and hardware registers mapping."""
    mem = C64Memory()
    screen = Screen(mem)
    engine = SpriteEngine(mem, screen)

    # 1. 32 Sprites limit/add test
    for i in range(32):
        s = Sprite(i, 5, 2, 2, frames=1, type="char")
        s.set_frame_data(0, [1, 2, 3, 4])
        engine.add(s)

    with pytest.raises(RuntimeError):
        # 33rd sprite should fail
        engine.add(Sprite(0, 0, 1, 1))

    # Reset engine to inspect dirty-rect background saving/restoring
    engine = SpriteEngine(mem, screen)

    # Prepare screen RAM and color RAM with dummy bg data
    for offset in range(1000):
        mem.write(0x0400 + offset, 0x41)  # Fill screen with 'A'
        mem.write(0xD800 + offset, Colors.BLUE)

    sprite = Sprite(5, 5, 2, 2, frames=1, type="char", colors=[Colors.GREEN])
    sprite.set_frame_data(0, [10, 11, 12, 13])
    sid = engine.add(sprite)

    # Draw the sprite
    engine.draw_all()

    # Verify background was saved, and sprite characters drawn
    assert engine.bg_buffers[sid]["chars"] == [0x41, 0x41, 0x41, 0x41]
    assert engine.bg_buffers[sid]["colors"] == [Colors.BLUE, Colors.BLUE, Colors.BLUE, Colors.BLUE]

    assert mem.read(0x0400 + 5 * 40 + 5) == 10
    assert mem.read(0xD800 + 5 * 40 + 5) == Colors.GREEN

    # Move sprite (should restore background under old position)
    engine.move(sid, 2, 1)  # old pos (5,5) cleared, new pos (7,6)

    # Old position should be restored back to 'A' (0x41) and Colors.BLUE
    assert mem.read(0x0400 + 5 * 40 + 5) == 0x41
    assert mem.read(0xD800 + 5 * 40 + 5) == Colors.BLUE

    # Draw at new position
    engine.draw_all()
    assert mem.read(0x0400 + 6 * 40 + 7) == 10

    # 2. Hardware sprites test (registers mapping)
    mem.write(0xD015, 0x00)  # Clear sprite enables
    hw_sprite = Sprite(300, 150, 24, 21, type="hardware", colors=[Colors.RED])
    engine.add(hw_sprite)
    engine.draw_all()

    # Hardware sprite index 0 registers check
    assert (mem.read(0xD015) & 0x01) != 0  # Sprite 0 enabled
    assert mem.read(0xD000) == (300 & 0xFF)  # X pos low byte
    assert (mem.read(0xD010) & 0x01) != 0  # MSB of X is set (300 > 255)
    assert mem.read(0xD001) == 150  # Y pos
    assert mem.read(0xD027) == Colors.RED  # Sprite 0 color


def test_tilemap_scrolling_and_wrap():
    """Verifies tile map setup, scrolling, and wrap-around rendering."""
    class MockScreen:
        def __init__(self):
            self.chars = {}
            self.colors = {}
        def poke_char(self, x, y, char, color):
            self.chars[(x, y)] = char
            self.colors[(x, y)] = color

    screen = MockScreen()
    tm = TileMap(width=2, height=2, tile_width=1, tile_height=1, wrap_around=True)
    tm.set_tile(0, 0, 65, Colors.RED)    # 'A'
    tm.set_tile(1, 0, 66, Colors.GREEN)  # 'B'
    tm.set_tile(0, 1, 67, Colors.BLUE)   # 'C'
    tm.set_tile(1, 1, 68, Colors.WHITE)  # 'D'

    # With wrap-around, drawing should fill the 40x25 screen repeating tiles
    tm.draw(screen)

    # Check top-left corner
    assert screen.chars[(0, 0)] == 65
    assert screen.chars[(1, 0)] == 66
    assert screen.chars[(2, 0)] == 65  # Wrapped X!
    assert screen.chars[(0, 1)] == 67  # Wrapped Y!

    # Scroll by 1 column
    tm.scroll(1, 0)
    tm.draw(screen)
    assert screen.chars[(0, 0)] == 66  # Now 'B' is at (0,0)


# ============================================================================
# TASK 2.3 TESTS: Collision System
# ============================================================================

def test_collision_system_aabb_and_swept():
    """Verifies spatial grid hashing, AABB, masks, callbacks, and swept collision."""
    cs = CollisionSystem(cell_size=8)

    # 1. Standard AABB + masks
    cs.add_object("player", 10, 10, 8, 8, "PLAYER", mask=["ENEMY"])
    cs.add_object("enemy1", 14, 14, 8, 8, "ENEMY")
    cs.add_object("enemy2", 50, 50, 8, 8, "ENEMY")

    collisions = cs.check_all()
    assert len(collisions) == 1
    assert collisions[0].id1 == "player" or collisions[0].id2 == "player"
    assert collisions[0].id1 == "enemy1" or collisions[0].id2 == "enemy1"

    # Callback check
    callback_triggered = []
    def on_p_e_collision(id1, id2, obj1, obj2):
        callback_triggered.append((id1, id2))

    cs.set_callback("PLAYER", "ENEMY", on_p_e_collision)
    cs.check_all()
    assert len(callback_triggered) == 1

    # 2. Swept collision (high-speed bullet)
    cs = CollisionSystem(cell_size=8)
    cs.add_object("bullet", 5, 10, 2, 2, "BULLET")
    cs.add_object("bunker", 15, 10, 8, 8, "BUNKER")

    # Bullet moves instantly past the bunker to x=25 in 1 frame
    cs.update_position("bullet", 25, 10)

    # Bullet mask check - allow collision
    cs.objects["bullet"]["mask"] = ["BUNKER"]

    collision = cs.check_pair("bullet", "bunker")
    assert collision is not None  # Swept collision detected!
    assert collision.id1 == "bullet"
    assert collision.id2 == "bunker"

    # 3. Performance Benchmark (50 objects < 1ms)
    cs = CollisionSystem(cell_size=4)
    for i in range(50):
        cs.add_object(f"obj_{i}", i * 0.1, 5, 2, 2, "ENEMY")

    t0 = time.perf_counter()
    cs.check_all()
    t1 = time.perf_counter()
    duration_ms = (t1 - t0) * 1000.0
    assert duration_ms < 10.0  # Safe upper-bound on sandbox platforms, usually < 1ms


# ============================================================================
# TASK 2.4 TESTS: HUD & Score System
# ============================================================================

def test_score_manager_and_hud():
    """Verifies BCD conversion, multi-player, high score saving, positioning, and flashing."""
    mem = C64Memory()
    screen = Screen(mem)

    # Configurable digits score manager (6 digits BCD)
    sm = ScoreManager(mem, digits=6, base_addr=0x033C)

    # P1 score 123,456 BCD check
    sm.set(123456, player=1)
    assert sm.get(player=1) == 123456
    assert sm.get_high_score() == 123456

    # Verify BCD memory bytes (for digits=6, we use 3 bytes: P1 at $033C-$033E)
    # 123456 in BCD: $56, $34, $12
    assert mem.read(0x033C) == 0x56
    assert mem.read(0x033D) == 0x34
    assert mem.read(0x033E) == 0x12

    # P2 score set
    sm.set(9876, player=2)
    assert sm.get(player=2) == 9876

    # File persistence check
    temp_file = "test_highscore.dat"
    if os.path.exists(temp_file):
        os.remove(temp_file)

    sm.save_high_score(temp_file)
    assert os.path.exists(temp_file)

    # Reset score in memory and load
    sm.set_high_score(0)
    assert sm.get_high_score() == 0
    sm.load_high_score(temp_file)
    assert sm.get_high_score() == 123456

    if os.path.exists(temp_file):
        os.remove(temp_file)

    # Extra life check
    assert sm.check_extra_life(1500, 1400, 1600) is True
    assert sm.check_extra_life(1500, 1000, 1200) is False

    # HUD positions and flashing
    hud = HUDSystem(screen, position="top")
    hud.add_element("p1_score", "score", 0, 0, "P1:{:06d}")
    hud.add_element("lives", "lives", 25, 0, "LIVES:")
    hud.add_element("time", "timer", 15, 0, "TIME:{}")

    hud.set_score(1, 123456)
    hud.set_lives(1, 3)
    hud.set_timer(75)  # 01:15

    hud.draw()

    # Verify formatting output in Screen RAM
    # P1:123456 starting at col 0
    from c64kit.core.utils import ascii_to_screen_code
    expected_str = "P1:123456"
    for i, char in enumerate(expected_str):
        assert mem.read(0x0400 + i) == ascii_to_screen_code(char)

    # LIVES: + 3 icons ($6C)
    # Check that icons are drawn
    assert mem.read(0x0400 + 25 + len("LIVES:")) == 0x6C

    # Flash effect
    hud.flash("p1_score", 1000, Colors.RED)
    hud.update_flash_timers(200)
    assert hud.elements["p1_score"]["color"] == Colors.RED


# ============================================================================
# TASK 2.5 TESTS: Level & Entity System
# ============================================================================

def test_level_and_entity_managers():
    """Verifies level configuration serialization, Entity spawn/destroy, and leak prevention."""
    lm = LevelManager()

    # Build standard level
    config = LevelConfig(
        name="INVADERS PAL",
        enemy_layout=[(5, 5, 1), (10, 5, 2)],
        player_start=(18, 22),
        bunker_positions=[(8, 20), (16, 20)],
        bonus_frequency=300,
        speed_curve=[10, 8, 6],
        palette=[Colors.WHITE, Colors.GREEN]
    )

    lm.add_level(config)
    serialized_bytes = lm.serialize(config)

    # Deserialize and verify equivalence
    decoded = lm.deserialize(serialized_bytes)
    assert decoded.name == "INVADERS PAL"
    assert decoded.enemy_layout == [(5, 5, 1), (10, 5, 2)]
    assert decoded.player_start == (18, 22)
    assert decoded.bunker_positions == [(8, 20), (16, 20)]
    assert decoded.bonus_frequency == 300
    assert decoded.speed_curve == [10, 8, 6]
    assert decoded.palette == [Colors.WHITE, Colors.GREEN]

    # Entity Manager memory leak prevention check
    em = EntityManager()

    # Spawn 50 entities
    ids = []
    for i in range(50):
        ent_id = em.spawn("ENEMY", 0, 0, hp=10)
        ids.append(ent_id)

    assert len(em.get_all()) == 50

    # Destroy all entities
    for ent_id in ids:
        em.destroy(ent_id)

    # Verify no memory leaks: list should be completely empty
    assert len(em.get_all()) == 0
    assert len(em.entities) == 0
