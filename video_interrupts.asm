; ****************************************************************************
; video_interrupts.asm
; ****************************************************************************
; Purpose: Interrupt service routines vectors configuration.
; ****************************************************************************
L0500                 SEI
                      LDA #<L09FD
                      STA IRQ_VEC
                      LDA #>L09FD
                      STA IRQ_VEC+1
                      CLI
                      RTS

; Standard Kernal IRQ
L0510                 SEI
                      LDA #$31
                      STA IRQ_VEC
                      LDA #$EA
                      STA IRQ_VEC+1
                      CLI
                      RTS

; Menu handler interrupt
L0520                 SEI
                      LDA #<L19A0
                      STA IRQ_VEC
                      LDA #>L19A0
                      STA IRQ_VEC+1
                      CLI
                      RTS

; Game interrupt + NMI (BRK handler)
L0530                 SEI
                      LDA #<L1750
                      STA IRQ_VEC
                      LDA #>L1750
                      STA IRQ_VEC+1
                      LDA #<L19F6
                      STA NMI_VEC
                      LDA #>L19F6
                      STA NMI_VEC+1
                      CLI
                      RTS

; ============================================================================
; SUONO SID (rimpiazza VIA PET $E848/$E84A)
; ============================================================================
