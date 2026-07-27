; ****************************************************************************
; game_loop.asm
; ****************************************************************************
; Purpose: Main core game loop and wave progression controller.
; ****************************************************************************
L0490                 LDA #$20
                      STA $0426      ; $8026 -> $0426
                      STA $0466      ; $8066 -> $0466
                      JSR L0E20
L049B                 JSR L0500
                      JSR L0C50
                      LDA #$00
                      JSR L0C78
                      JSR L0D60
                      JSR L0800
L04AC                 JSR L0806
                      ; Input joystick C64 porta 2 via CIA1
                      LDA CIA1_PRB
                      CMP #$EF       ; Fire button?
                      BEQ L04B6
L04B6                 LDA M03C7
                      BNE L04BB
L04BB                 LDA M03CE
                      BEQ L04D0
                      CMP #$06
                      BCS L04AC
                      JSR L04EC
                      JMP L04AC
                      JSR L0510
                      JMP COLDRESET
L04D0                 JSR L17D0
                      BMI L04D0
L04D5                 LDA M03F3
                      BMI L04D5
L04DA                 LDA M03F5
                      BMI L04DA
L04DF                 LDA ZD7
                      BMI L04DF
                      JSR L0500
                      JSR L0E51
                      JMP L049B

; === NUOVA ONDATA ===
L04EC                 CMP #$01
                      BNE L04F4
                      LDA #$01
                      LDY SYSTEM_TYPE
                      BEQ L04EC_PAL
                      LDA #$02        ; Slightly longer delay for NTSC
L04EC_PAL             STA L08F3_SELF+1
                      NOP
L04F4                 LDA #$04
                      STA L08D1_SELF+1
                      RTS

; ============================================================================
; INTERRUPT VECTORS (C64 $0314/$0315 invece di PET $0090/$0091)
; ============================================================================

; Game tick interrupt
