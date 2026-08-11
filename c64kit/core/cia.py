# c64kit/core/cia.py
from typing import Dict, Any

class CIABase:
    """Base class emulating a MOS 6526 Complex Interface Adapter (CIA)."""

    def __init__(self, is_cia2: bool = False):
        self.is_cia2 = is_cia2
        self.registers = bytearray(16)

        # Timer values
        self.timer_a = 0xFFFF
        self.timer_a_latch = 0xFFFF
        self.timer_a_running = False

        self.timer_b = 0xFFFF
        self.timer_b_latch = 0xFFFF
        self.timer_b_running = False

        # Interrupt mask and active status
        self.icr_mask = 0x00
        self.icr_status = 0x00

        # TOD Clock
        self.tod_hours = 0
        self.tod_minutes = 0
        self.tod_seconds = 0
        self.tod_tenths = 0

    def write(self, reg: int, val: int) -> None:
        """Writes to a specific register (0-15)."""
        reg &= 0x0F
        val &= 0xFF
        self.registers[reg] = val

        if reg == 0x00:    # PRA
            pass
        elif reg == 0x01:  # PRB
            pass
        elif reg == 0x02:  # DDRA
            pass
        elif reg == 0x03:  # DDRB
            pass
        elif reg == 0x04:  # TA_LO
            self.timer_a_latch = (self.timer_a_latch & 0xFF00) | val
        elif reg == 0x05:  # TA_HI
            self.timer_a_latch = (self.timer_a_latch & 0x00FF) | (val << 8)
            if not self.timer_a_running:
                self.timer_a = self.timer_a_latch
        elif reg == 0x06:  # TB_LO
            self.timer_b_latch = (self.timer_b_latch & 0xFF00) | val
        elif reg == 0x07:  # TB_HI
            self.timer_b_latch = (self.timer_b_latch & 0x00FF) | (val << 8)
            if not self.timer_b_running:
                self.timer_b = self.timer_b_latch
        elif reg == 0x08:  # TOD Tenths
            self.tod_tenths = val & 0x0F
        elif reg == 0x09:  # TOD Seconds
            self.tod_seconds = val & 0x7F
        elif reg == 0x0A:  # TOD Minutes
            self.tod_minutes = val & 0x7F
        elif reg == 0x0B:  # TOD Hours
            self.tod_hours = val & 0x1F
        elif reg == 0x0D:  # ICR
            # Bit 7 of the value written determines Set/Clear mode
            if val & 0x80:
                self.icr_mask |= (val & 0x1F)
            else:
                self.icr_mask &= ~(val & 0x1F)
        elif reg == 0x0E:  # CRA
            self.timer_a_running = bool(val & 0x01)
            if val & 0x10:  # Force load
                self.timer_a = self.timer_a_latch
        elif reg == 0x0F:  # CRB
            self.timer_b_running = bool(val & 0x01)
            if val & 0x10:  # Force load
                self.timer_b = self.timer_b_latch

    def read(self, reg: int) -> int:
        """Reads from a specific register (0-15)."""
        reg &= 0x0F
        if reg == 0x04:    # TA_LO
            return self.timer_a & 0xFF
        elif reg == 0x05:  # TA_HI
            return (self.timer_a >> 8) & 0xFF
        elif reg == 0x06:  # TB_LO
            return self.timer_b & 0xFF
        elif reg == 0x07:  # TB_HI
            return (self.timer_b >> 8) & 0xFF
        elif reg == 0x08:  # TOD Tenths
            return self.tod_tenths
        elif reg == 0x09:  # TOD Seconds
            return self.tod_seconds
        elif reg == 0x0A:  # TOD Minutes
            return self.tod_minutes
        elif reg == 0x0B:  # TOD Hours
            return self.tod_hours
        elif reg == 0x0D:  # ICR
            # Reading the ICR returns current status flags and then clears them.
            status = self.icr_status
            self.icr_status = 0x00
            return status
        return self.registers[reg]

    def tick(self, cycles: int = 1) -> bool:
        """
        Simulate clock cycles passing.
        Returns True if an interrupt is generated during these cycles.
        """
        interrupt_triggered = False

        # Timer A
        if self.timer_a_running:
            self.timer_a -= cycles
            if self.timer_a <= 0:
                self.timer_a = self.timer_a_latch
                self.icr_status |= 0x01  # Bit 0: Timer A
                if self.icr_mask & 0x01:
                    self.icr_status |= 0x80  # Bit 7: Active interrupt flag
                    interrupt_triggered = True

                # Timer B counting Timer A underflows (CRB bits 5-6 == 01)
                if self.timer_b_running and ((self.registers[0x0F] & 0x60) == 0x40):
                    self.timer_b -= 1
                    if self.timer_b <= 0:
                        self.timer_b = self.timer_b_latch
                        self.icr_status |= 0x02  # Bit 1: Timer B
                        if self.icr_mask & 0x02:
                            self.icr_status |= 0x80
                            interrupt_triggered = True

        # Timer B (independent cycle count, CRB bits 5-6 == 00)
        if self.timer_b_running and ((self.registers[0x0F] & 0x60) == 0x00):
            self.timer_b -= cycles
            if self.timer_b <= 0:
                self.timer_b = self.timer_b_latch
                self.icr_status |= 0x02  # Bit 1: Timer B
                if self.icr_mask & 0x02:
                    self.icr_status |= 0x80
                    interrupt_triggered = True

        return interrupt_triggered


class CIA1(CIABase):
    """Emulation of CIA1 chip ($DC00-$DC0F) - Joystick, Keyboard and Timer IRQs."""

    def __init__(self):
        super().__init__(is_cia2=False)


class CIA2(CIABase):
    """Emulation of CIA2 chip ($DD00-$DD0F) - VIC bank switching, User port, NMIs."""

    def __init__(self):
        super().__init__(is_cia2=True)
