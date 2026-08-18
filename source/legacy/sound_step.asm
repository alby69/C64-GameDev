; ****************************************************************************
; sound_step.asm
; ****************************************************************************
; Purpose: SID sound generator triggers for step sounds.
; ****************************************************************************
L0550                 LDA M03DC
                      BPL L0556
                      RTS
L0556                 INC M02A3
                      LDA M02A3
                      AND #$0F
                      TAX
                      LDA FREQ_TABLE,X
                      LDX M03CC
                      BEQ L056A
                      CLC
                      ADC #$50
L056A                 STA SID_FREQ_LO1
                      LDA #$00
                      STA SID_FREQ_HI1
                      ; Impulso sonoro - noise gate on/off
                      LDA #$81
                      STA SID_CTRL1
                      LDA #$80
                      STA SID_CTRL1
                      RTS

; ============================================================================
; INPUT - JOYSTICK + MOVIMENTO BASE
; ============================================================================
; PET usava PIA $E810/$E812. C64 usa CIA1 $DC00/$DC01.
; Il joystick porta 2 si legge così:
;   $DC00 = $FF (sel. linee), $DC01 bit 2=sin, 3=des, 4=fire
