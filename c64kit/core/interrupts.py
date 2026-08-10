# c64kit/core/interrupts.py
from typing import List, Optional
from .memory import C64Memory
from .constants import RAM_IRQ_VEC, RAM_NMI_VEC, IRQ_VEC, NMI_VEC

class Interrupt:
    """Represents a simulated interrupt source."""

    def __init__(self, source: str, priority: int, is_nmi: bool = False):
        self.source = source
        self.priority = priority
        self.is_nmi = is_nmi


class InterruptManager:
    """Manages IRQ and NMI routing and priority queue simulation for the C64 kit."""

    def __init__(self, memory: C64Memory):
        self.mem = memory
        self.irq_active = False
        self.nmi_active = False
        self.pending_irqs: List[Interrupt] = []
        self.pending_nmis: List[Interrupt] = []

    def trigger_irq(self, source: str, priority: int = 1) -> None:
        """Triggers an IRQ from a specific source (e.g. 'raster', 'timer_a')."""
        if not any(i.source == source for i in self.pending_irqs):
            self.pending_irqs.append(Interrupt(source, priority, is_nmi=False))
            self.pending_irqs.sort(key=lambda x: x.priority, reverse=True)
            self.irq_active = True

    def trigger_nmi(self, source: str, priority: int = 1) -> None:
        """Triggers an NMI from a specific source (e.g. 'restore', 'timer_a_cia2')."""
        if not any(i.source == source for i in self.pending_nmis):
            self.pending_nmis.append(Interrupt(source, priority, is_nmi=True))
            self.pending_nmis.sort(key=lambda x: x.priority, reverse=True)
            self.nmi_active = True

    def clear_irq(self, source: str) -> None:
        """Clears a pending IRQ source."""
        self.pending_irqs = [i for i in self.pending_irqs if i.source != source]
        if not self.pending_irqs:
            self.irq_active = False

    def clear_nmi(self, source: str) -> None:
        """Clears a pending NMI source."""
        self.pending_nmis = [i for i in self.pending_nmis if i.source != source]
        if not self.pending_nmis:
            self.nmi_active = False

    def get_irq_vector(self) -> int:
        """Returns the memory address pointed to by the IRQ vector."""
        ram_vec = self.mem.read(RAM_IRQ_VEC) | (self.mem.read(RAM_IRQ_VEC + 1) << 8)
        if ram_vec == 0 or ram_vec == 0xFFFF:
            return self.mem.read(IRQ_VEC) | (self.mem.read(IRQ_VEC + 1) << 8)
        return ram_vec

    def get_nmi_vector(self) -> int:
        """Returns the memory address pointed to by the NMI vector."""
        ram_vec = self.mem.read(RAM_NMI_VEC) | (self.mem.read(RAM_NMI_VEC + 1) << 8)
        if ram_vec == 0 or ram_vec == 0xFFFF:
            return self.mem.read(NMI_VEC) | (self.mem.read(NMI_VEC + 1) << 8)
        return ram_vec

    def execute_interrupt_handlers(self) -> Optional[int]:
        """
        Simulates servicing the highest priority active interrupt.
        Returns the destination PC vector if handled, or None.
        """
        if self.nmi_active and self.pending_nmis:
            return self.get_nmi_vector()
        elif self.irq_active and self.pending_irqs:
            return self.get_irq_vector()
        return None
