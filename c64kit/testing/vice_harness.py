"""c64kit/testing/vice_harness.py

VICE Emulator Test Harness for automated integration testing and screenshots verification.
"""

import os
import time
import subprocess
import socket
from typing import Callable, Any, Optional, Dict, Tuple
from PIL import Image, ImageChops

__all__ = [
    "SIDState",
    "VICEHarness",
]


class SIDState:
    """Represents the emulated or read SID audio registers state."""

    def __init__(self, voice1_freq: int = 0, voice2_freq: int = 0, voice3_freq: int = 0, volume: int = 0):
        self.voice1_freq = voice1_freq
        self.voice2_freq = voice2_freq
        self.voice3_freq = voice3_freq
        self.volume = volume


class VICEHarness:
    """Manages VICE x64sc execution, remote monitor interfacing, and screenshot assertion."""

    def __init__(self, bin_path: str = "x64sc", monitor_port: int = 6510):
        self.bin_path = bin_path
        self.monitor_port = monitor_port
        self.process: Optional[subprocess.Popen] = None
        self.socket: Optional[socket.socket] = None
        # Simulated memory for headless testing mode when actual VICE process isn't running
        self._sim_memory = bytearray(65536)
        self._sim_screen_color = (0, 0, 0)

    def start_emulator(self, prg_path: Optional[str] = None, headless: bool = True) -> None:
        """Launches the x64sc emulator process in remote monitor mode.

        Args:
            prg_path: Optional PRG file to load at startup.
            headless: Run with virtual display parameters if xvfb is needed.
        """
        cmd = [self.bin_path, "-keepobj", "-remotemonitor", "-remotemonitoraddress", f"127.0.0.1:{self.monitor_port}"]
        if prg_path:
            cmd.append(prg_path)

        # In headless environment we can run inside xvfb-run
        if headless and not os.environ.get("DISPLAY"):
            cmd = ["xvfb-run", "-a"] + cmd

        try:
            self.process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            # Give the emulator a moment to start up and bind to the port
            time.sleep(1.0)
            if self.process.poll() is not None:
                # Process exited immediately
                raise FileNotFoundError()
            self._connect_monitor()
        except (FileNotFoundError, OSError):
            # Fall back to simulated execution state for offline environment testing
            print("VICE x64sc not found. Running in offline/simulated harness mode.")
            self.process = None

    def _connect_monitor(self) -> None:
        """Connects to the remotemonitor socket of VICE."""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(2.0)
            self.socket.connect(("127.0.0.1", self.monitor_port))
            # Read banner
            self.socket.recv(1024)
        except Exception as e:
            print(f"Failed to connect to VICE remote monitor: {e}")
            self.socket = None

    def send_monitor_command(self, cmd: str) -> str:
        """Sends a command to the remote monitor and returns the response.

        Args:
            cmd: Command string (e.g. 'm 0400 04ff').
        """
        if not self.socket:
            return ""
        try:
            self.socket.sendall(f"{cmd}\n".encode("utf-8"))
            # Read response
            time.sleep(0.05)
            response = self.socket.recv(4096).decode("utf-8")
            return response
        except Exception:
            return ""

    def load_prg(self, path: str, address: Optional[int] = None) -> None:
        """Loads a C64 PRG file into memory.

        Args:
            path: Path to the .prg file.
            address: Optional load address override.
        """
        if not os.path.exists(path):
            raise FileNotFoundError(f"PRG file '{path}' not found.")

        # Read binary data
        with open(path, "rb") as f:
            data = f.read()

        if len(data) < 2:
            return

        # First 2 bytes are the load address
        load_addr = address if address is not None else (data[1] << 8 | data[0])
        bytes_to_load = data[2:]

        if self.socket:
            # Write to emulator via monitor block writing command (if supported) or send file load command
            self.send_monitor_command(f"l \"{path}\" 0")
        else:
            # Write to offline simulated memory
            for i, b in enumerate(bytes_to_load):
                target = (load_addr + i) & 0xFFFF
                self._sim_memory[target] = b

    def read_memory(self, addr: int, length: int = 1) -> bytes:
        """Reads a block of memory from the C64.

        Args:
            addr: Memory start address (e.g., 0x0400).
            length: Number of bytes to read.
        """
        if self.socket:
            # Parse remotemonitor memory output
            # Format: >C:0400  41 42 43 ...
            hex_addr = f"{addr:04x}"
            hex_end = f"{(addr + length - 1):04x}"
            res = self.send_monitor_command(f"m {hex_addr} {hex_end}")

            bytes_list = []
            for line in res.splitlines():
                if ":" in line:
                    parts = line.split(":", 1)[1].strip().split()
                    for p in parts:
                        if len(p) == 2:
                            try:
                                bytes_list.append(int(p, 16))
                            except ValueError:
                                pass
            if len(bytes_list) >= length:
                return bytes(bytes_list[:length])

        # Simulated memory fallback
        return bytes(self._sim_memory[addr:addr+length])

    def press_key(self, key: str) -> None:
        """Simulates a keypress on the C64 keyboard.

        Args:
            key: Key name (e.g., 'SPACE', 'A', 'RETURN').
        """
        if self.socket:
            self.send_monitor_command(f"keybuf {key}")
        else:
            # Simulate keyboard matrix buffer state at $0289-$028F if needed
            pass

    def run_until(self, condition: Callable[[], bool], timeout_ms: int = 5000) -> bool:
        """Runs the emulator until a condition is met or timeout is reached.

        Args:
            condition: Callable that returns True when target state is reached.
            timeout_ms: Timeout duration in milliseconds.
        """
        start_time = time.time()
        timeout_s = timeout_ms / 1000.0

        while (time.time() - start_time) < timeout_s:
            if condition():
                return True
            time.sleep(0.05)

        return False

    def get_screenshot(self) -> Image.Image:
        """Captures a screenshot of the C64 screen.

        Returns:
            PIL Image object representing the screen.
        """
        if self.socket:
            # In real headless VICE monitor we can use screendump monitor command
            dump_file = "screendump.png"
            self.send_monitor_command(f"screendump {dump_file}")
            if os.path.exists(dump_file):
                img = Image.open(dump_file).convert("RGB")
                try:
                    os.remove(dump_file)
                except OSError:
                    pass
                return img

        # Simulated screenshot fallback: 320x200 pixel block
        return Image.new("RGB", (320, 200), self._sim_screen_color)

    def compare_screenshot(self, reference_path: str, threshold: float = 0.01) -> bool:
        """Compares current emulator screenshot with a reference image.

        Args:
            reference_path: Path to the reference screenshot PNG.
            threshold: Acceptable RMS error ratio (0.0 = identical).

        Returns:
            True if image differences are within the acceptable threshold.
        """
        if not os.path.exists(reference_path):
            return False

        img_ref = Image.open(reference_path).convert("RGB")
        img_curr = self.get_screenshot().resize(img_ref.size)

        diff = ImageChops.difference(img_ref, img_curr)
        diff_seq = diff.getdata()

        # Calculate root-mean-square difference
        sum_sq = sum(sum(val**2 for val in px) for px in diff_seq)
        rms = (sum_sq / (len(diff_seq) * 3)) ** 0.5
        norm_rms = rms / 255.0

        return norm_rms <= threshold

    def get_sid_state(self) -> SIDState:
        """Reads and parses current SID state registers.

        Returns:
            SIDState containing frequencies and global volume.
        """
        # SID base register is $D400
        sid_bytes = self.read_memory(0xD400, 25)
        if len(sid_bytes) < 25:
            return SIDState()

        v1_freq = sid_bytes[1] << 8 | sid_bytes[0]
        v2_freq = sid_bytes[8] << 8 | sid_bytes[7]
        v3_freq = sid_bytes[15] << 8 | sid_bytes[14]
        volume = sid_bytes[24] & 0x0F

        return SIDState(v1_freq, v2_freq, v3_freq, volume)

    def stop_emulator(self) -> None:
        """Stops the emulator process and disconnects the monitor socket."""
        if self.socket:
            try:
                self.socket.close()
            except Exception:
                pass
            self.socket = None

        if self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=2.0)
            except Exception:
                try:
                    self.process.kill()
                except Exception:
                    pass
            self.process = None
