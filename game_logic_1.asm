; ****************************************************************************
; game_logic_1.asm
; ****************************************************************************
; Purpose: Enemies movement and bullet processing, part 1 of core game logic.
; ****************************************************************************
L0600                 LDA ZD7
                      BMI L0605
                      RTS
L0605                 LDY #$2A
                      LDA M03CB
                      BEQ L0620
                      DEC M03CB
                      BEQ L0615
                      TYA
                      STA (ZD6),Y
                      RTS
L0615                 LDY #$2A
                      LDA #$20
                      STA (ZD6),Y
                      LDA #$00
                      STA ZD7
                      RTS
L0620                 LDY #$2A
                      LDA #$20
                      STA (ZD6),Y
                      SEC
                      LDA ZD6
                      SBC #$28
                      BCS L062F
                      DEC ZD7
L062F                 STA ZD6
                      LDA (ZD6),Y
                      STA M03CD
                      CMP #$20
                      BNE L0655
                      LDA ZD7
                      CMP #$05       ; PET $81 -> C64 $05
                      BCS L0646
                      LDA ZD6
                      CMP #$28
                      BCC L065C
L0646                 LDA M03D0
                      AND #$01
                      TAX
                      LDA SPRDATA_BASE+$80,X
                      STA (ZD6),Y
                      RTS
L0655                 LDA M03CD
                      CMP #$A0
                      BNE L0668
L065C                 LDA #$03
L065E                 STA M03CB
                      LDA #$2A
                      STA (ZD6),Y
L0665                 RTS
L0668                 LDA ZD7
                      CMP #$05       ; PET $81 -> C64 $05
                      BCS L0683
                      LDA ZD6
                      CMP #Z50
                      BCS L0683
                      LDA M03DC
                      BMI L0683
                      LDA #$01
                      STA M03CC
                      LDA #$08
                      BNE L065E
L0683                 LDA M03CD
                      CMP #$24
                      BNE L068D
                      JMP L0D00
L068D                 SEC
                      LDA ZD6
                      SBC #$29
                      BCS L0696
                      DEC ZD7
L0696                 STA ZD6
                      LDY #$00
L069A                 LDX #$00
L069C                 LDA Z0A,X
                      CMP ZD6
                      BNE L06A8
                      LDA Z0B,X
                      CMP ZD7
                      BEQ L06C9
L06A8                 INX
                      INX
                      CPX #Z50
                      BCC L069C
                      INY
                      CPY #$06
                      BEQ L0665
                      CPY #$03
                      BEQ L06BB
                      LDA #$01
                      BNE L06BD
L06BB                 LDA #$25
L06BD                 CLC
                      ADC ZD6
                      BCC L06C4
                      INC ZD7
L06C4                 STA ZD6
                      JMP L069A
L06C9                 LDA ZFB
                      PHA
                      LDA ZFC
                      PHA
                      LDA ZD6
                      STA ZFB
                      LDA ZD7
                      STA ZFC
                      LDA #$08
                      STA ZB3
                      JSR L0C00
                      DEC M03CE
                      TXA
                      AND #$FE
                      TAX
                      LDA M0340,X
                      JSR L0C78
                      LDA #$00
                      STA M0340,X
                      STA Z0B,X
                      LDY #$2A
                      LDA #$20
                      STA (ZD6),Y
                      LDA #$00
                      STA ZD7
                      LDA #$10
                      STA M03D9
L0701                 JSR L09C0
                      JSR L09B0
                      DEC M03E0
                      BNE L0715
                      LDA M03E1
                      STA M03E0
                      JSR L0580
L0715                 DEC M03E4
                      BNE L0723
                      LDA M03E5
                      STA M03E4
                      JSR L0B06
L0723                 JSR L0770
                      DEC M03E6
                      BNE L0734
                      LDA M03E7
                      STA M03E6
                      JSR L0F70
L0734                 DEC M03D9
                      BNE L0701
                      LDA M03C1
                      PHA
                      LDA #$00
                      STA M03C1
                      LDA #$04
                      STA ZB3
                      JSR L0C00
                      PLA
                      STA M03C1
                      PLA
                      STA ZFC
                      PLA
                      STA ZFB
                      RTS

; ============================================================================
; VARIE
; ============================================================================

L0770                 JSR L0780
                      JSR L163C
                      JSR L0550
                      JSR L16E0
                      RTS

L0780                 LDA ZD7
                      BPL L0785
                      RTS
L0785                 LDA M03D2
                      BEQ L078E
                      DEC M03D2
                      RTS
L078E                 LDA M03C9
                      AND #$01
                      BEQ L079B
                      LDA #$00
                      STA M03D1
                      RTS
L079B                 LDA M03D1
                      BEQ L07A1
                      RTS
L07A1                 LDA #$01
                      STA M03D1
                      LDA M03CA
                      STA M03D0
                      LSR
                      CLC
                      ADC #$71
                      STA ZD6
                      LDA #$05       ; PET $83 -> C64 $07 ($83-$7E=$05)
                      STA ZD7
                      LDA #$01
                      STA M03D2
                      INC M0286
                      LDA M0286
                      CMP #$0F
                      BNE L07CA
                      LDA #$00
                      STA M0286
L07CA                 LDA #$08
                      STA M02A4
                      RTS

L07E0                 JSR L0E20
                      LDA #$00       ; Silenzia SID
                      STA SID_CTRL1
                      STA SID_FREQ_LO1
                      RTS

L07FD                 JMP L0907

; ============================================================================
; CICLO MOVIMENTO INVADERS
; ============================================================================

L0800                 JSR L0980
                      JSR L09D0
L0806                 JSR L0930
                      LDY M0280
L080C                 LDX SCRD1100_DATA,Y
                      LDA M0340,X
                      BEQ L07FD
                      LDA Z0A,X
                      STA ZFB
                      LDA Z0B,X
                      STA ZFC
                      SEI
                      LDA M03C0
                      BMI L0832
                      CLC
                      ADC ZFB
                      BCC L082B
                      INC ZFC
                      INC Z0B,X
L082B                 STA ZFB
                      STA Z0A,X
                      JMP L0840
L0832                 DEC ZFB
                      DEC Z0A,X
                      LDA ZFB
                      CMP #$FF
                      BNE L0840
                      DEC ZFC
                      DEC Z0B,X
L0840                 LDA M0340,X
                      ORA M03C1
                      STA ZB3
                      JSR L0C00
                      CLI
                      LDA M03E0
                      STY M03D5
                      CMP #$05
                      BCS L087C
                      LDY #$A2
                      LDA (ZFB),Y
                      AND #$7F
                      CMP #$7F
                      BEQ L087C
                      CMP #$63
                      BEQ L087C
                      CMP #$7E
                      BEQ L087C
                      CMP #$7C
                      BEQ L087C
                      CMP #$62
                      BEQ L087C
                      CMP #$19
                      BEQ L087C
                      CMP #$61
                      BEQ L087C
                      CMP #$60
                      BNE L0880
L087C                 JMP L08F0
L0880                 LDA ZFC
                      AND #$03
                      STA M03D7
                      LDA ZFB
                      STA M03D6
L088C                 SEC
                      LDA M03D6
                      SBC #$28
                      STA M03D6
                      BCS L089A
                      DEC M03D7
L089A                 CMP #$28
                      BCS L088C
                      LDA M03D7
                      BNE L088C
                      CLC
                      ADC #$02
                      STA M03D6
                      LDA M03CA
                      LSR
                      SEC
                      SBC M03D6
                      BPL L08B5
                      EOR #$FF
L08B5                 ASL
                      ASL
                      NOP
                      NOP
                      NOP
                      NOP
                      JSR L09F0
                      ADC SPRDATA_BASE+$E0,Y
                      NOP
                      NOP
                      BCS L08F0
                      INC M03D4
                      LDY #$00
L08CA                 LDA M03F1,Y
                      BPL L08D8
                      INY
                      INY
L08D1_SELF            CPY #$06       ; Self-mod (max 3 missili, 6 byte)
                      BCC L08CA
                      JMP L08F0
L08D8                 SEI
                      CLC
                      LDA ZFB
                      ADC #$7A
                      STA M03F0,Y
                      BCC L08E5
                      INC ZFC
L08E5                 LDA ZFC
                      STA M03F1,Y
                      CLI
                      INC M03DD
L08F0                 LDY M03D5
                      LDA #$08
                      STA M03C4
L08F3_SELF            LDA #$00       ; Self-mod (delay)
                      STA M03C5
L08FD                 DEC M03C5
                      BNE L08FD
                      DEC M03C4
                      BNE L08FD
L0907                 INY
                      TYA
                      AND #$3F
                      CMP #$28
                      BNE L0918
                      LDA #$04
                      EOR M03C1
                      STA M03C1
                      RTS
L0918                 JMP L080C

; ============================================================================
; CONTROLLO BORDO INVADERS
; ============================================================================

L0930                 JSR L09B0
                      LDA #$28
                      STA ZFB
                      LDA #$04       ; PET $80 -> C64 $04
                      STA ZFC
                      LDX #$17
L0940                 LDA #$20
                      LDY #$00
                      CMP (ZFB),Y
                      BNE L095D
                      LDY #$27
                      CMP (ZFB),Y
                      BNE L095D
                      CLC
                      LDA ZFB
                      ADC #$28
                      BCC L0957
                      INC ZFC
L0957                 STA ZFB
                      DEX
                      BNE L0940
                      RTS
L095D                 LDA M03C0
                      CMP #$28
                      BNE L096D
                      LDA M03C6
                      EOR #$FF
                      STA M03C0
                      RTS
L096D                 STA M03C6
                      LDA #$28
                      STA M03C0
                      LDA #$40
                      EOR M0280
                      STA M0280
                      RTS

; ============================================================================
; INIZIALIZZA POSIZIONI
; ============================================================================

L0980                 LDX #$00
                      LDY M03DA
L0985                 LDA SCRD1000_DATA,X
                      CLC
                      ADC SPRDATA_BASE+$B0,Y
                      STA Z0A,X
                      LDA SCRD1000_DATA+1,X
                      STA Z0B,X
                      BCC L0997
                      INC Z0B,X
L0997                 INX
                      INX
                      CPX #Z50
                      BCC L0985
                      INC M03DA
                      LDA SPRDATA_BASE+$B1,Y
                      BEQ L09A6
                      RTS
L09A6                 LDA #$01
                      STA M03DA
                      RTS

; ============================================================================
; SINCRONIZZAZIONE (VIA PET -> raster C64)
; ============================================================================
