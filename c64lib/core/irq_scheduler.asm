; ============================================================================
; MODULE: irq_scheduler.asm
; PURPOSE: Hardware IRQ vector scheduler and task runner
; DEPENDS: c64lib/hal/c64_hardware.inc
; CLOBBER: A, X, Y
; ============================================================================

#include "c64lib/hal/c64_hardware.inc"

; ----------------------------------------------------------------------------
; ROUTINE: irq_init
; PURPOSE: Install the custom IRQ master scheduler and clear task queue
; ----------------------------------------------------------------------------
irq_init:
        LDX #47
        LDA #$00
_irq_clear_queue:
        STA TASK_QUEUE,X
        DEX
        BPL _irq_clear_queue

        STA mRasterCallback
        STA mRasterCallback+1

        PHP
        SEI
        LDA #<_irq_master_handler
        STA IRQ_VEC
        LDA #>_irq_master_handler
        STA IRQ_VEC+1
        PLP
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: irq_add_task
; PURPOSE: Add a task to the 50Hz scheduler queue
; INPUT: A = priority, X = interval, Y = callback_lo, mIrqCbHi = callback_hi
; OUTPUT: A = task_id (0-7), Carry=1 if ok, Carry=0 if full
; ----------------------------------------------------------------------------
irq_add_task:
        STA mIrqTempPri
        STX mIrqTempInt
        STY mIrqTempCbLo

        ; Find free slot
        LDX #0                  ; Offset (0, 6, 12, ..., 42)
_irq_find_slot:
        LDA TASK_QUEUE,X        ; Active byte
        BEQ _irq_slot_found
        TXA
        CLC
        ADC #6
        CMP #48
        BCC _irq_find_slot

        ; Queue full
        CLC
        RTS

_irq_slot_found:
        LDA #1
        STA TASK_QUEUE,X        ; Mark active
        LDA mIrqTempPri
        STA TASK_QUEUE+1,X      ; Priority
        LDA mIrqTempInt
        STA TASK_QUEUE+2,X      ; Interval
        STA TASK_QUEUE+3,X      ; Counter = Interval
        LDA mIrqTempCbLo
        STA TASK_QUEUE+4,X      ; Callback Lo
        LDA mIrqCbHi
        STA TASK_QUEUE+5,X      ; Callback Hi

        ; Calculate task ID (offset / 6)
        TXA
        LDY #0
_irq_div6:
        CMP #6
        BCC _irq_div6_done
        SBC #6
        INY
        JMP _irq_div6
_irq_div6_done:
        TYA                     ; Task ID (0-7)
        SEC                     ; Carry = 1 (success)
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: irq_remove_task
; PURPOSE: Remove task from scheduler
; INPUT: A = task_id (0-7)
; ----------------------------------------------------------------------------
irq_remove_task:
        ; Offset = task_id * 6
        ASL                     ; *2
        STA mIrqTempId
        ASL                     ; *4
        CLC
        ADC mIrqTempId
        TAX
        LDA #0
        STA TASK_QUEUE,X        ; Deactivate slot
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: irq_set_raster
; PURPOSE: Setup a raster interrupt
; INPUT: A = raster line, Y = callback_lo, mIrqCbHi = callback_hi
; ----------------------------------------------------------------------------
irq_set_raster:
        STA VIC_RASTER
        STY mRasterCallback
        LDA mIrqCbHi
        STA mRasterCallback+1

        ; Enable raster interrupt in VIC-II
        LDA VIC_IRQMASK
        ORA #$01
        STA VIC_IRQMASK
        RTS

; ----------------------------------------------------------------------------
; ROUTINE: irq_wait_vsync
; PURPOSE: Sync/wait for system vertical sync line
; ----------------------------------------------------------------------------
irq_wait_vsync:
_irq_wait_vsync_loop:
        LDA VIC_RASTER
        CMP mSyncLineVal
        BNE _irq_wait_vsync_loop
        RTS

; ----------------------------------------------------------------------------
; MASTER IRQ SCHEDULER HANDLER
; ----------------------------------------------------------------------------
_irq_master_handler:
        LDA VIC_IRR
        AND #$01
        BEQ _irq_check_tasks

        STA VIC_IRR             ; Acknowledge raster interrupt

        LDA mRasterCallback+1
        BEQ _irq_check_tasks

        JSR _irq_call_raster

_irq_check_tasks:
        LDX #0
_irq_task_proc_loop:
        LDA TASK_QUEUE,X
        BEQ _irq_next_task

        DEC TASK_QUEUE+3,X      ; Decrement counter
        BNE _irq_next_task

        LDA TASK_QUEUE+2,X      ; Reset counter to interval
        STA TASK_QUEUE+3,X

        TXA
        PHA                     ; Save offset

        LDA TASK_QUEUE+4,X
        STA mIrqCallPtr
        LDA TASK_QUEUE+5,X
        STA mIrqCallPtr+1

        JSR _irq_do_indirect_call

        PLA
        TAX                     ; Restore offset

_irq_next_task:
        TXA
        CLC
        ADC #6
        CMP #48
        BCC _irq_task_proc_loop

        JMP KERNAL_IRQ

_irq_do_indirect_call:
        JMP (mIrqCallPtr)

_irq_call_raster:
        JMP (mRasterCallback)

; ----------------------------------------------------------------------------
; STORAGE VARIABLES
; ----------------------------------------------------------------------------
mSyncLineVal:    .byte $80      ; Default PAL sync line
mIrqCbHi:        .byte $00      ; High byte parameter for callbacks
mRasterCallback: .word $0000

mIrqTempPri:     .byte $00
mIrqTempInt:     .byte $00
mIrqTempCbLo:    .byte $00
mIrqTempId:      .byte $00

mIrqCallPtr:     .word $0000

; Task queue address (8 tasks * 6 bytes = 48 bytes)
; Declared in standard memory space to avoid KERNAL Page 2 conflicts
TASK_QUEUE:
        .dsb 48, 0
