; ****************************************************************************
; game_logic_2.asm
; ****************************************************************************
; Purpose: Game ticks, player missile, collision system, score, and screens, part 2 of core game logic.
; ****************************************************************************
L09D0                 LDX #$00
                      LDY #$00
L09D4                 LDA SCRD1000_DATA+Z50,X
                      STA M0340,Y
                      INY
                      INY
                      INX
                      CPX #$29
                      BCC L09D4
                      RTS

; ============================================================================
; RNG HELPER
; ============================================================================

L09F0                 PHA
                      LDA M03C8
                      AND #$0F
                      TAY
                      PLA
                      INC M03C8
                      RTS

; ============================================================================
; INTERRUPT HANDLER: GAME TICK
; ============================================================================

L09FD                 LDA FIRE_DEBOUNCE_TIMER
                      BEQ L09FD_DEB_DONE
                      DEC FIRE_DEBOUNCE_TIMER
L09FD_DEB_DONE        JSR L0A56
                      DEC M03E0
                      BNE L0A0E
                      LDA M03E1
                      STA M03E0
                      JSR L0580
L0A0E                 DEC M03E2
                      BNE L0A1C
                      LDA M03E3
                      STA M03E2
                      JSR L0600
L0A1C                 DEC M03E4
                      BNE L0A2A
                      LDA M03E5
                      STA M03E4
                      JSR L0B06
L0A2A                 JSR L0780
                      JSR L0A60
                      LDA M03E6
                      CMP #$10
                      BCS L0A3A
                      JSR L0F30
L0A3A                 DEC M03E6
                      BNE L0A48
                      LDA M03E7
                      STA M03E6
                      JSR L0F70
L0A48                 JSR L0C93
                      JSR L0BE0
                      JSR L17A0
                      JMP KERNAL_IRQ

L0A56                 JSR L163C
                      JSR L0550
                      JSR L16EA
                      RTS

; ============================================================================
; DISPLAY VITE
; ============================================================================

L0A60                 LDX #$20
                      TXA
L0A63                 STA $0400,X    ; $8000 -> $0400
                      INX
                      CPX #$28
                      BNE L0A63
                      LDX #$17
                      LDY M03DB
                      TYA
                      JSR L0CB6
                      LDX #$20
                      DEY
                      BEQ L0A8B
                      BMI L0A8B
L0A7B                 LDA #$6C
                      STA $0400,X
                      LDA #ZFC
                      STA $0401,X
                      INX
                      INX
                      INX
                      DEY
                      BNE L0A7B
L0A8B                 RTS

; ============================================================================
; INVADER BONUS / MISTERIA
; ============================================================================

L0A90                 LDA M03CB
                      BEQ L0A96
                      RTS
L0A96                 LDA M0287
                      BNE L0AE3
                      SED
                      LDA M0286
                      ASL
                      PHA
                      TAX
                      LDA SPRDATA_BASE+$F0,X
                      CLC
                      ADC M033C
                      STA M033C
                      LDA SPRDATA_BASE+$F1,X
                      ADC M033D
                      STA M033D
                      CLD
                      JSR L0C93
                      LDY #$10
                      LDX M03DC
                      JSR L0FB8
                      LDA M03DC
                      CLC
                      ADC #$26
                      TAX
                      PLA
                      TAY
                      LDA SPRDATA_BASE+$F0,Y
                      PHA
                      JSR L0CB6
                      PLA
                      JSR L0CB2
                      LDA SPRDATA_BASE+$F1,Y
                      BEQ L0ADD
                      JSR L0CB6
L0ADD                 LDA #$10
L0ADF                 STA M0287
L0AE2                 RTS
L0AE3                 DEC M0287
                      BNE L0ADF+1
                      LDY #$10
                      LDX M03DC
                      JSR L0FB8
                      LDA #$FF
                      STA M03DC
                      LDA #$00
                      STA M03CC
                      STA M03DD
                      RTS

; ============================================================================
; MISSILE GIOCATORE
; ============================================================================

L0B00                 JMP L0B90

L0B06                 LDX #$00
L0B08                 LDA M03F1,X
                      CMP #$01
                      BEQ L0B00
                      STA Z6F
                      LDA M03F0,X
                      STA Z6E
                      LDY #$00
                      LDA #$20
                      STA (Z6E),Y
                      LDA M03F8,X
                      BNE L0B34
                      LDA #$01
                      STA M03F8,X
                      STA M03F1,X
                      DEC M03D4
                      JMP L0B00
L0B34                 LDA Z6E
                      CLC
                      ADC #$28
                      BCC L0B40
                      INC Z6F
                      INC M03F1,X
L0B40                 STA Z6E
                      STA M03F0,X
                      LDA (Z6E),Y
                      CMP #$20
                      BNE L0B6C
                      LDA Z6E
                      CMP #$C0       ; PET $80C0 -> C64 $04C0
                      BCC L0B57
                      LDA Z6F
                      CMP #$05       ; PET $83 -> C64 $05
                      BCS L0B60
L0B57                 LDA #$24
                      STA (Z6E),Y
                      JMP L0B00
L0B60                 LDA #$2A
                      STA (Z6E),Y
                      LDA #$00
                      STA M03F8,X
                      JMP L0B00
L0B6C                 CMP #$60
                      BEQ L0B60
                      CMP #$47
                      BEQ L0BA0
                      CMP #$48
                      BEQ L0BA0
                      CMP #$A0
                      BEQ L0B60
                      LDA Z6E
                      CMP #$98       ; PET $8098 -> C64 $0498
                      BCC L0B8B
                      LDA Z6F
                      CMP #$05
                      BCC L0B8B
                      JMP L0DA0
L0B8B                 LDA #$01
                      STA M03F1,X
L0B90                 INX
                      INX
                      CPX #$06
                      BCC L0B97
                      RTS
L0B97                 JMP L0B08

L0BA0                 TYA
                      PHA
                      LDY M03D8
                      LDA SID_RANDOM  ; RNG via SID invece di Kernal PET
                      INC M03D8
                      CMP #$50
                      BCC L0BB8
                      CMP #$A0
                      BCC L0BC8
                      LDY #$2A
                      JSR L065C
L0BB8                 LDA #$00
                      STA M03F8,Y
                      LDY #$00
                      LDA #$2A
                      STA (Z6E),Y
L0BC3                 PLA
                      TAY
                      JMP L0B90
L0BC8                 LDY #$2A
                      JSR L065C
                      JMP L0BC3

; ============================================================================
; MISTERIA CHECK
; ============================================================================

L0BE0                 LDA M03C7
                      BNE L0BE6
L0BE5                 RTS
L0BE6                 DEC M0289
                      BNE L0BE5
                      LDA #$01
                      STA M03DB
                      JMP L0DAD

; ============================================================================
; DISEGNA SPRITE INVADER
; ============================================================================
; Legge dati sprite da SPRDATA_BASE e li scrive a schermo.
; Ogni sprite è 5×3 caratteri (15 byte). Indice ZB3 × 16 byte.

L0C00                 TXA
                      PHA
                      TYA
                      PHA
                      LDY #$00
                      LDA ZFC
                      CMP #$07       ; PET $83 -> C64 $07
                      BCC L0C1B
                      LDA ZFB
                      CMP #$47
                      BCC L0C1B
                      LDA #$01
                      STA M03C7
                      LDX #$03
                      BNE L0C1D
L0C1B                 LDX ZB3
L0C1D                 DEX
                      TXA
                      ORA M03C1
                      ASL
                      ASL
                      ASL
                      ASL          ; ×16 (4 x 4 nibble = sprite offset)
                      TAX
                      INX
                      JSR L09B0
L0C2B                 LDA SPRDATA_BASE,X
                      STA (ZFB),Y
                      INX
                      INY
                      TYA
                      AND #$05
                      CMP #$05
                      BNE L0C2B
                      TYA
                      CLC
                      ADC #$23
                      CMP #$78
                      BEQ L0C44
                      TAY
                      BNE L0C2B
L0C44                 PLA
                      TAY
                      PLA
                      TAX
                      RTS

; ============================================================================
; CLEAR + SETUP PUNTEGGIO
; ============================================================================

L0C50                 LDA #$93       ; CLR/HOME
                      JSR BSOUT
                      JSR L09B0
                      LDX #$00
                      LDA #$60       ; Bunker char
L0C5C                 STA $07C0,X    ; $83C0 -> $07C0
                      INX
                      CPX #$28
                      BNE L0C5C
                      JSR L0C93
                      JMP L0A60

; ============================================================================
; PUNTEGGIO
; ============================================================================

L0C78                 JSR L0CE0
                      ASL
                      NOP
                      NOP
                      NOP
                      NOP
                      SED
                      CLC
                      ADC M033C
                      STA M033C
                      BCC L0C92
                      LDA M033D
                      ADC #$00
                      STA M033D
L0C92                 CLD
L0C93                 TXA
                      PHA
                      LDX #$03
                      LDA M033C
                      JSR L0CB6
                      LDA M033C
                      JSR L0CB2
                      LDA M033D
                      JSR L0CB6
                      LDA M033D
                      JSR L0CC0
                      PLA
                      TAX
                      RTS

L0CB2                 LSR
                      LSR
                      LSR
                      LSR
L0CB6                 AND #$0F
                      ORA #$30       ; PETSCII digit
                      STA $0406,X    ; $8006 -> $0406
                      DEX
                      RTS

L0CC0                 JSR L0CB2
                      LDA M033D
                      CMP #$15       ; 1500 punti = vita extra
                      BCS L0CCB
L0CCA                 RTS
L0CCB                 NOP
                      LDA M0288
                      BNE L0CCA
                      INC M03DB      ; Vita extra!
                      JSR L0A60
                      LDA #$FF
                      STA M0288
                      RTS

; ============================================================================
; CALCOLA PUNTI
; ============================================================================

L0CE0                 PHA
                      TXA
                      PHA
                      LDX #$00
L0CE5                 LDA SCRD1300_PTS,X
                      BNE L0CF1
                      PLA
                      TAX
                      PLA
                      ASL
                      ASL
                      ASL
                      RTS
L0CF1                 STA $0400,X    ; $8000 -> $0400
                      INX
                      BNE L0CE5
                      RTS

; ============================================================================
; VARIE COLLISIONI
; ============================================================================

L0D00                 NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      LDX M03D8
                      CLD
                      EOR ZCB,X
                      CMP #$A0
                      BCC L0D20
                      JMP L065C

L0D20                 LDX #$00
L0D22                 LDA ZD6
                      CLC
                      ADC #$2A
                      TAY
                      LDA ZD7
L0D2E                 CMP M03F1,X
                      BNE L0D39
                      TYA
                      CMP M03F0,X
                      BEQ L0D40
L0D39                 INX
                      INX
                      CPX #$06
                      BCC L0D22
                      RTS
L0D40                 LDA #$00
                      STA M03F8,X
                      LDY M03D8
                      LDA SID_RANDOM
                      CMP #$80
                      BCC L0D58
                      LDY #$2A
                      JMP L065C
L0D58                 RTS

; ============================================================================
; DISEGNA BUNKER
; ============================================================================
; I bunker sono disegnati sulla riga $07xx dello schermo C64
; (corrisponde alla riga $83xx del PET).

L0D60                 LDA #$06       ; PET $82 -> C64 $06
                      STA ZFC        ; (high byte indirizzo bunker)
                      LDA #$FF
                      STA ZFB
                      JSR L0D88
                      LDA #$07       ; PET $83 -> C64 $07
                      STA ZFC
                      LDA #$06
                      STA ZFB
                      JSR L0D88
                      LDA #$0E
L0D78                 STA ZFB
                      JSR L0D88
                      LDA #$15
                      STA ZFB
                      JMP L0D88

L0D88                 LDX #$00
                      LDY #$00
                      LDA BUNKER_DATA,X
L0D8F                 LDY BUNKER_DATA+1,X
                      STA (ZFB),Y
                      INX
                      INX
                      LDA BUNKER_DATA,X
                      BNE L0D8F
                      RTS

L0D9D                 JMP L0B90

; ============================================================================
; BASE DISTRUTTA
; ============================================================================

L0DA0                 LDA M0283
                      BEQ L0D9D
                      LDA #$01
                      STA M03F1,X
                      STA M03F8,X
L0DAD                 LDA #$00
                      STA M0283
                      LDA ZD7
                      BPL L0DB9
                      JSR L0615
L0DB9                 NOP
                      NOP
                      NOP
                      LDY #$02
                      STY M0281
                      LDA #$80
                      STA M0282
L0DC6                 LDA M0281
                      EOR #$01
                      STA M0281
                      TAY
                      LDX M03CA
                      JSR L05B3
                      DEC M03E4
                      BNE L0DE3
                      LDA M03E5
                      STA M03E4
                      JSR L0B06
L0DE3                 JSR L09C0
                      JSR L17D9
                      DEC M0282
                      BNE L0DC6
                      LDX M03CA
                      LDA #$04
                      JSR L05B3
                      DEC M03DB
                      JSR L0A60
                      JMP L17F0

; ============================================================================
; INIZIALIZZAZIONE TIMER
; ============================================================================

L0E00                 LDA #$02
                      STA M03E1
                      STA M03E3
                      LDA #$04
                      STA M03E5
                      LDA #$06
                      STA M03E7
                      LDA #$00
                      STA M033E
                      STA M033F
L0E20                 LDA #$00
                      STA M033C
                      STA M033D
                      STA M03C6
                      STA M03C7
                      STA M03D5
                      STA M03DA
                      STA M0288
                      STA FIRE_DEBOUNCE_TIMER
                      LDA #$03
                      STA M03DB
                      LDA #$FF
                      STA M0286
                      LDA #$01
                      STA M03F1
                      STA M03F3
                      STA M03F5
                      LDA #$10
                      STA M0289
L0E51                 LDA #$00
                      STA M03C1
                      STA M03D8
                      STA M0280
                      STA M03CB
                      STA M03CC
                      STA M03DD
                      STA M0287
                      LDA #$01
                      STA M03C0
                      STA ZFC
                      STA ZD7
                      STA Z6F
                      LDA #$28
                      STA M03CE
                      LDA #$FF
                      STA M03DC
                      STA M0286
                      LDA #$60
                      STA M03E0
                      JSR L0EF0
L0E88                 LDA #$00
                      STA M03CD
                      STA M03D0
                      STA M03D1
                      STA M03D2
                      STA M03D4
                      LDA #$01
                      STA M0283
                      LDA #$04
                      STA M03CA
                      LDA #$08
                      STA M03E4
                      LDA #$01
                      STA M03E6
                      LDA #$08
                      LDX SYSTEM_TYPE
                      BEQ L0E88_PAL
                      LDA #$0A        ; Slightly longer delay for NTSC to match PAL speed
L0E88_PAL             STA L08F3_SELF+1
                      LDA #$FF
                      STA M03C9
                      LDA #$06
                      STA L08D1_SELF+1
                      LDA #$0F
                      STA SID_VOL
                      RTS

L0EF0                 STA M03E2
                      STA M02A0
                      RTS

; ============================================================================
; GAME OVER
; ============================================================================

L0F00                 LDA M03DB
                      BNE L0F08
                      JMP L0FB0
L0F08                 LDA #$00
                      STA M0284
                      STA M0285
L0F10                 DEC M0284
                      BNE L0F10
                      DEC M0285
                      BNE L0F10
                      JSR L0E88
                      LDA IRQ_VEC
                      CMP #<L1750
                      BEQ L0F25
                      RTS
L0F25                 JSR L0520
                      JMP L19F2

; ============================================================================
; BONUS INVADER CHECK
; ============================================================================

L0F30                 LDX #$00
L0F32                 LDA $0428,X    ; $8028 -> $0428
                      CMP #$20
                      BEQ L0F3A
                      RTS
L0F3A                 INX
                      CPX #$51
                      BNE L0F32
                      LDA M03DC
                      BMI L0F45
                      RTS
L0F45                 LDA M03DD
                      CMP #$18
                      BCS L0F4D
L0F4C                 RTS
L0F4D                 LDA M03CE
                      CMP #$08
                      BCC L0F4C
                      LDA M0286
                      AND #$01
                      BNE L0F62
                      LDA #$01
                      LDX #$00
                      BEQ L0F66
L0F62                 LDA #$FF
                      LDX #$22
L0F66                 STA M03DE
                      STX M03DC
                      RTS

L0F6C                 RTS

; ============================================================================
; BONUS MOVEMENT
; ============================================================================

L0F70                 LDA M03DC
                      BMI L0F6C
                      LDA M03CC
                      BNE L0FD8
                      LDA M03DC
                      CLC
                      ADC M03DE
                      BEQ L0F90
                      CMP #$22
                      BEQ L0F90
                      STA M03DC
                      TAX
                      LDY #$00
                      JMP L0FB8
L0F90                 TAX
                      BEQ L0F96
                      DEX
                      BNE L0F97
L0F96                 INX
L0F97                 LDY #$10
                      JSR L0FB8
                      LDA #$FF
                      STA M03DC
                      LDA #$00
                      STA M03DD
                      RTS

L0FB0                 JSR L0510
                      JMP L18C6

L0FB8                 LDA BONUS_DATA,Y
                      BNE L0FBE
                      RTS
L0FBE                 STA $0428,X    ; $8028 -> $0428
                      INY
                      INX
                      TYA
                      AND #$0F
                      CMP #$07
                      BNE L0FB8
                      TXA
                      CLC
                      ADC #$21
                      TAX
                      JMP L0FB8

L0FD8                 JMP L0A90

; ============================================================================
; STAMPA STRINGHE
; ============================================================================

L1600                 LDY #$00
L1602                 LDA (ZFB),Y
                      CMP #$FF
                      BNE L1609
                      RTS
L1609                 CMP #$20
                      BCC L1610
                      JSR L1680
L1610                 JSR BSOUT
                      INY
                      BNE L1602
                      RTS

COLDRESET             LDX #$FF
                      TXS
                      JMP ($FFFC)

; ============================================================================
; TRAINER PLAV
; ============================================================================

L1617                 LDX #$FF
                      TXS
                      JSR L1800
                      JMP L19E6

L1620                 LDY #$00
                      LDX #$00
L1624                 LDA SCRD1500_TRAIN,X
                      BNE L162A
                      RTS
L162A                 STA (ZFB),Y
                      LDA SCRD1500_TRAIN+$40,X
                      CLC
                      ADC ZFB
                      BCC L1636
                      INC ZFC
L1636                 STA ZFB
                      INX
                      BNE L1624
                      RTS

L163C                 LDA M02A0
                      BEQ L1652
                      DEC M02A0
                      BMI L1647
                      RTS
L1647                 LDA M03CE
                      SEC
                      SBC #$01
                      ASL
                      STA M02A0
                      RTS
L1652                 DEC M02A1
                      BEQ L1661
                      LDX M02A2
                      LDA FREQ_TABLE2,X
                      STA SID_FREQ_LO1
                      RTS
L1661                 LDA #$00
                      STA SID_FREQ_LO1
                      DEC M02A2
                      BNE L1670
                      LDA #$04
                      STA M02A2
L1670                 LDA #$FF
                      STA M02A0
                      LDA #$03
                      STA M02A1
                      RTS

; DELAYS
L1680                 PHA
                      LDA #$20
                      STA M0293
                      LDA #$00
                      STA M0292
L168B                 DEC M0292
                      BNE L168B
                      DEC M0293
                      BNE L168B
                      PLA
                      RTS

L16A0                 PHA
                      LDA #$02
                      STA M0294
                      LDA #$00
                      STA M0293
                      STA M0292
L16AE                 DEC M0292
                      BNE L16AE
                      DEC M0293
                      BNE L16AE
                      DEC M0294
                      BNE L16AE
                      PLA
                      RTS

; CLEAR SCREEN
L16C0                 LDA #$00
                      STA ZFB
                      LDA #>$0400
                      STA ZFC
                      LDX #$04
                      LDY #$28
                      LDA #$20
L16CE                 STA (ZFB),Y
                      INY
                      BNE L16CE
                      INC ZFC
                      DEX
                      BNE L16CE
                      RTS

; SOUND EFFECTS
L16E0                 LDX M03D9
                      LDA FREQ_EFFECT,X
                      STA SID_FREQ_LO1
                      RTS

L16EA                 LDX M02A4
                      BNE L16F0
                      RTS
L16F0                 DEC M02A4
                      LDA FREQ_EFFECT,X
                      STA SID_FREQ_LO1
                      LDA #$81
                      STA SID_CTRL1
                      LDA #$80
                      STA SID_CTRL1
                      RTS

; GAME ROUND
L1700                 JSR L07E0
                      LDA Z8F
                      STA M03D8
                      JSR L0C50
                      LDA #$00
                      JSR L0C78
                      JSR L0D60
                      JSR L0800
L1717                 JSR L0806
                      LDA M03C7
                      BNE L1722
                      JMP L1717
L1722                 RTS

; ANIMAZIONE CASUALE
L1728                 LDA Z8F
                      AND #$3F
                      TAY
                      INC Z8F
                      LDA SID_RANDOM
                      CMP #$60
                      BCS L173C
                      LDA #$7F
                      BCC L1746
L173C                 CMP #$A0
                      BCC L1744
                      LDA #$BF
                      BCS L1746
L1744                 LDA #$FF
L1746                 LDX SPRDATA_BASE+$01,Y
                      BMI L174D
                      AND #$FE
L174D                 JMP L058D

; ============================================================================
; HARDWARE INTERRUPT
; ============================================================================

L1750                 DEC M03E0
                      BNE L175E
                      LDA M03E1
                      STA M03E0
                      JSR L1728
L175E                 DEC M03E2
                      BNE L176C
                      LDA M03E3
                      STA M03E2
                      JSR L0600
L176C                 DEC M03E4
                      BNE L177A
                      LDA M03E5
                      STA M03E4
                      JSR L0B06
L177A                 JSR L0780
                      JSR L0A60
                      JSR L0C93
                      JSR L17A0
                      JMP KERNAL_IRQ

; ============================================================================
; HIGH SCORE DISPLAY
; ============================================================================

L17A0                 LDX #$00
L17A2                 LDA SCRD1300_HIGH,X
                      BEQ L17B0
                      STA $040F,X    ; $800F -> $040F
                      INX
                      JMP L17A2
L17B0                 LDX #$11
                      LDA M033E
                      JSR L0CB6
                      LDA M033E
                      JSR L0CB2
                      LDA M033F
                      JSR L0CB6
                      LDA M033F
                      JMP L0CB2

; WAIT ALIGN
L17D0                 LDA #$08
                      STA SID_CTRL1
                      LDA M03F1
                      RTS

L17D9                 JSR L09B0
                      JSR L17E0
                      RTS

L17E0                 LDA M0282
                      AND #$01
                      BEQ L17E9
                      LDA #$FF
L17E9                 STA SID_FREQ_LO1
                      RTS

L17F0                 JSR L17D0
                      JMP L0F00

; ============================================================================
; TRAINER SEQUENCE
; ============================================================================

L1800                 JSR L16C0
                      LDA #<SCRD1400_TXT
                      STA ZFB
                      LDA #>SCRD1400_TXT
                      STA ZFC
                      JSR L1600
                      LDA #$6E
                      STA ZFB
                      LDA #$05       ; $81 -> $05
                      STA ZFC
                      JSR L1620
                      LDA #<SCRD1400_TXT+$38
                      STA ZFB
                      LDA #>SCRD1400_TXT
                      STA ZFC
                      JSR L1600
                      JSR L16A0
                      NOP
                      LDA #$74
                      STA ZFB
                      LDA #$04       ; $80 -> $04
                      STA ZFC
                      LDX #$11
                      LDA #$03
                      STA ZB3
L1836                 JSR L0C00
                      LDA M03C1
                      EOR #$04
                      STA M03C1
                      JSR L1680
                      DEX
                      BEQ L1850
                      DEC ZFB
                      BNE L1836
L1850                 LDA #$16
                      STA $0426      ; $8026 -> $0426
                      STA $0466      ; $8066 -> $0466
                      LDX #$11
L185A                 JSR L0C00
                      LDA M03C1
                      EOR #$04
                      STA M03C1
                      JSR L18B0
                      DEX
                      BEQ L186F
                      INC ZFB
                      BNE L185A
L186F                 JSR L18C0
                      STA $0426
                      STA $0466
                      LDX #$11
L187A                 JSR L0C00
                      LDA M03C1
                      EOR #$04
                      STA M03C1
                      JSR L1680
                      DEX
                      BEQ L1890
                      DEC ZFB
                      BNE L187A
L1890                 JSR L16A0
                      LDA #$20
                      STA $0426
                      STA $0466
                      LDA #$04
                      STA ZB3
                      LDA #$00
                      STA M03C1
                      JSR L0C00
                      LDA #$19
                      STA $048C      ; $808C -> $048C
                      JMP L16A0

L18B0                 JSR L1680
                      LDY #$28
                      LDA #$20
                      STA (ZFB),Y
                      LDY #$00
                      RTS

L18C0                 JSR L16A0
                      LDA #$19
                      RTS

; GAME OVER SCREEN
L18C6                 LDA M033D
                      CMP M033F
                      BEQ L18D2
                      BCS L18DA
                      BCC L18E9
L18D2                 LDA M033C
                      CMP M033E
                      BCC L18E6
L18DA                 LDA M033C
                      STA M033E
                      LDA M033D
                      STA M033F
L18E6                 JSR L17A0
L18E9                 LDA #<SCRD1350_TXT
                      STA ZFB
                      LDA #>SCRD1350_TXT
                      STA ZFC
                      JSR L1600
                      JSR L16A0
L18F7                 JSR GET
                      BNE L18F7
                      JMP L19DB

; CONTROLS SCREEN
L1900                 JSR L16C0
                      LDA #<SCRD1500_TXT
                      STA ZFB
                      LDA #>SCRD1500_TXT
                      STA ZFC
                      JSR L1600
                      JSR L16A0
                      LDA #$4B
                      STA ZFB
                      LDA #$04       ; $80 -> $04
                      STA ZFC
                      LDX #$13
                      LDA #$03
                      STA ZB3
                      LDA #$00
                      STA M03C1
L192B                 JSR L0C00
                      LDA M03C1
                      EOR #$04
                      STA M03C1
                      JSR L1680
                      DEX
                      BEQ L1940
                      DEC ZFB
                      BNE L192B
L1940                 NOP
                      NOP
                      NOP
                      LDA #$B3
                      STA Z6E
                      LDA #$04       ; $80 -> $04
                      STA Z6F
                      LDY #$00
L194D                 LDA #$20
                      STA (Z6E),Y
                      LDA Z6E
                      CLC
                      ADC #$28
                      BCC L195A
                      INC Z6F
L195A                 STA Z6E
                      LDA (Z6E),Y
                      CMP #$20
                      BNE L1970
                      LDA #$24
                      STA (Z6E),Y
                      JSR L1680
                      JMP L194D
L1970                 LDA #$2A
                      STA (Z6E),Y
                      JSR L1680
                      JSR L1680
                      JSR L1680
                      LDA #$20
                      STA (Z6E),Y
                      JSR L16A0
                      LDA #$00
                      STA M03C1
                      LDA #$04
                      STA ZB3
                      JSR L0C00
                      JSR L16A0
                      RTS

; MENU INTERRUPT HANDLER
L19A0                 JSR GET
                      BNE L19A8
                      JMP KERNAL_IRQ
L19A8                 JSR L16C0
                      JSR L0510
                      LDX #$00
L19B0                 LDA SCRD1300_MENU,X
                      STA $0598,X    ; $8198 -> $0598
                      INX
                      CPX #$16
                      BNE L19B0
L19BB                 JSR GET
                      BEQ L19BB
                      JSR L16C0
                      LDX #$00
L19C5                 LDA SCRD1300_MENU2,X
                      STA $059C,X    ; $819C -> $059C
                      INX
                      CPX #$0E
                      BNE L19C5
                      JSR L16A0
                      JMP L0490

; MAIN FLOW
L19D8                 JSR L0E00
L19DB                 JSR L0520
                      BNE L19E3
L19E0                 JSR L1900
L19E3                 JMP L1617

L19E6                 JSR L0530
                      JSR L1700
                      JSR L0520
                      JMP L19E0

L19F2                 LDX #$FF
                      TXS
                      NOP
                      JSR L0520
                      JMP L19E0

L19F6                 JSR L0520
                      JMP L19E0

; ============================================================================
; DATI DEL GIOCO
; ============================================================================

; Frequenze suono passo invader
