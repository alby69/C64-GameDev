;
; ****************************************************************************
; Original PET Invaders source disassembly.
; Disassembled by: Dave McMurtrie <dave@commodore.international>
; Date: August, 2023
; ****************************************************************************
*                  = $0401
                     ; add a BASIC sys (1039) loader
                     .byte $0d,$04,$0a,$00
                     .null $9e, format("(%4d)", 1039)
                     .byte $00,$00

; PET kernal routines called by Invaders code
BASRST             = $B3FF
BSOUT              = $FFD2
GET                = $FFE4
CRSRBLNK           = $E458
; PET hardware locations used by Invaders
PIADDRA            = $E810
PIADDRB            = $E812
VIAPB              = $E840
TIMR2LO            = $E848
VIASHIFTREG        = $E84A
; Zero page locations used
Z0A                = $0A
Z0B                = $0B
Z50                = $50
Z51                = $51
Z52                = $52
Z53                = $53
Z6E                = $6E
Z6F                = $6F
Z8F                = $8F
ZCB                = $CB
ZB3                = $B3
ZD6                = $D6
ZD7                = $D7
ZFB                = $FB
ZFC                = $FC
; Interrupt Vectors
IV0090             = $0090
IV0091             = $0091
IV0092             = $0092
IV0093             = $0093
; Random memory locations used
M0280              = $0280
M0281              = $0281
M0282              = $0282
M0283              = $0283
M0284              = $0284
M0285              = $0285
M0286              = $0286
M0287              = $0287
M0288              = $0288
M0289              = $0289
M0292              = $0292
M0293              = $0293
M0294              = $0294
M02A0              = $02A0
M02A1              = $02A1
M02A2              = $02A2
M02A3              = $02A3
M02A4              = $02A4
M033C              = $033C
M033D              = $033D
M033E              = $033E
M033F              = $033F
M0340              = $0340
M03C0              = $03C0
M03C1              = $03C1
M03C4              = $03C4
M03C5              = $03C5
M03C6              = $03C6
M03C7              = $03C7
M03C8              = $03C8
M03C9              = $03C9
M03CA              = $03CA
M03CB              = $03CB
M03CC              = $03CC
M03CD              = $03CD
M03CE              = $03CE
M03D0              = $03D0
M03D1              = $03D1
M03D2              = $03D2
M03D4              = $03D4
M03D5              = $03D5
M03D6              = $03D6
M03D7              = $03D7
M03D8              = $03D8
M03D9              = $03D9
M03DA              = $03DA
M03DB              = $03DB
M03DC              = $03DC
M03DD              = $03DD
M03DE              = $03DE
M03E0              = $03E0
M03E1              = $03E1
M03E2              = $03E2
M03E3              = $03E3
M03E4              = $03E4
M03E5              = $03E5
M03E6              = $03E6
M03E7              = $03E7
M03F0              = $03F0
M03F1              = $03F1
M03F3              = $03F3
M03F5              = $03F5
M03F8              = $03F8

; Main program start.
; Display the "how to get sound" screen.
START                NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     LDA #<SCRD1C00
                     STA Z50
                     LDA #>SCRD1C00
                     STA Z51
                     LDA #$80
                     STA Z53
                     LDY #$00
                     STY Z52
                     LDX #$04
L0428                LDA (Z50),Y
                     STA (Z52),Y
                     INY
                     BNE L0428
                     INC Z51
                     INC Z53
                     DEX
                     BNE L0428
L0436                JSR GET   ; wait for a key to be pressed
                     BNE L0436
L043B                JSR GET
                     BEQ L043B
                     LDA #$93
                     JSR BSOUT
                     JMP L19D8


L0490                LDA #$20
                     STA SCRD1200+$26
                     STA SCRD1200+$66 
                     JSR L0E20
L049B                JSR L0500
                     JSR L0C50
                     LDA #$00
                     JSR L0C78
                     JSR L0D60
                     JSR L0800
L04AC                JSR L0806
                     LDA PIADDRB
                     CMP #$EF
                     BEQ L04B6
L04B6                LDA M03C7
                     BNE L04BB
L04BB                LDA M03CE
                     BEQ L04D0
                     CMP #$06
                     BCS L04AC
                     JSR L04EC
                     JMP L04AC
                     JSR L0510
                     JMP BASRST 
L04D0                JSR L17D0
                     BMI L04D0
L04D5                LDA M03F3
                     BMI L04D5
L04DA                LDA M03F5
                     BMI L04DA
L04DF                LDA ZD7
                     BMI L04DF
                     JSR L0500
                     JSR L0E51
                     JMP L049B


L04EC                CMP #$01
                     BNE L04F4
                     STA L08F3+$01
                     NOP
L04F4                LDA #$04
                     STA L08D1+$01
                     RTS


L0500                SEI
                     LDA #<L09FD
                     STA IV0090
                     LDA #>L09FD
                     STA IV0091
                     CLI
                     RTS



; set up hardware interrupt
L0510                SEI
                     LDA #$55
                     STA IV0090
                     LDA #$E4
                     STA IV0091
                     CLI
                     RTS


; set up hardware interrupt
L0520                SEI
                     LDA #<L19A0
                     STA IV0090
                     LDA #>L19A0
                     STA IV0091
                     CLI
                     RTS


; set up interrupt handlers
L0530                SEI
                     LDA #<L1750
                     STA IV0090
                     LDA #>L1750
                     STA IV0091
                     LDA #<L19F6
                     STA IV0092
                     LDA #>L19F6
                     STA IV0093
                     CLI
                     RTS


L0550                LDA M03DC
                     BPL L0556
                     RTS
L0556                INC M02A3
                     LDA M02A3
                     AND #$0F
                     TAX
                     LDA SCRD1300+$C8,X
                     LDX M03CC
                     BEQ L056A
                     CLC
                     ADC #$50
L056A                STA TIMR2LO 
                     RTS


L0580                LDA #$04
                     STA PIADDRA
L0585                LDA PIADDRB
                     CMP PIADDRB
                     BNE L0585
L058D                STA M03C9
                     LDX M03CA
                     ORA #$3F
                     CMP #$7F
                     BNE L05A1
                     CPX #$3F
                     BEQ L05AD
                     INX
                     STX M03CA
L05A1                CMP #$BF
                     BNE L05AD
                     CPX #$04
                     BEQ L05AD
                     DEX
                     STX M03CA
L05AD                NOP
                     NOP
                     NOP
                     TXA
                     AND #$01
L05B3                ASL A
                     ASL A
                     ASL A
                     ASL A
                     TAY
                     TXA
                     LSR A
                     TAX
L05BB                LDA SCRD1100+$80,Y
                     STA $8398,X
                     INX
                     INY
                     TYA
                     AND #$0F
                     CMP #$0E
                     BEQ L05D8
                     CMP #$07
                     BNE L05BB
                     TXA
                     CLC
                     ADC #$21
                     TAX
                     JMP L05BB
                     NOP
                     NOP
L05D8                RTS


L0600                LDA ZD7
                     BMI L0605
                     RTS
L0605                LDY #$2A
                     LDA M03CB
                     BEQ L0620
                     DEC M03CB
                     BEQ L0615
                     TYA
                     STA (ZD6),Y
                     RTS
L0615                LDY #$2A
                     LDA #$20
                     STA (ZD6),Y
                     LDA #$00
                     STA ZD7
                     RTS
L0620                LDY #$2A
                     LDA #$20
                     STA (ZD6),Y
                     SEC
                     LDA ZD6
                     SBC #$28
                     BCS L062F
                     DEC ZD7
L062F                STA ZD6
                     LDA (ZD6),Y
                     STA M03CD
                     CMP #$20
                     BNE L0655
                     LDA ZD7
                     CMP #$81
                     BCS L0646
                     LDA ZD6
                     CMP #$28
                     BCC L065C
L0646                LDA M03D0
                     AND #$01
                     TAX
                     LDA SCRD1200+$80,X
                     STA (ZD6),Y
                     RTS
                     NOP
                     NOP
                     NOP
L0655                LDA M03CD
                     CMP #$A0
                     BNE L0668
L065C                LDA #$03
L065E                STA M03CB
                     LDA #$2A
                     STA (ZD6),Y
L0665                RTS
                     NOP
                     NOP
L0668                LDA ZD7
                     CMP #$81
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
                     NOP
L0683                LDA M03CD
                     CMP #$24
                     BNE L068D
                     JMP L0D00
L068D                SEC
                     LDA ZD6
                     SBC #$29
                     BCS L0696
                     DEC ZD7
L0696                STA ZD6
                     LDY #$00
L069A                LDX #$00
L069C                LDA Z0A,X
                     CMP ZD6
                     BNE L06A8
                     LDA Z0B,X
                     CMP ZD7
                     BEQ L06C9
L06A8                INX
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
L06BB                LDA #$25
L06BD                CLC
                     ADC ZD6
                     BCC L06C4
                     INC ZD7
L06C4                STA ZD6
                     JMP L069A
L06C9                LDA ZFB
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
L0701                JSR L09C0
                     JSR L09B0
                     DEC M03E0
                     BNE L0715
                     LDA M03E1
                     STA M03E0
                     JSR L0580
L0715                DEC M03E4
                     BNE L0723
                     LDA M03E5
                     STA M03E4
                     JSR L0B06
L0723                JSR L0770
                     DEC M03E6
                     BNE L0734
                     LDA M03E7
                     STA M03E6
                     JSR L0F70
L0734                DEC M03D9
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


L0770                JSR L0780
                     JSR L163C
                     JSR L0550
                     JSR L16E0
                     RTS


L0780                LDA ZD7
                     BPL L0785
                     RTS
L0785                LDA M03D2
                     BEQ L078E
                     DEC M03D2
                     RTS
L078E                LDA M03C9
                     AND #$01
                     BEQ L079B
                     LDA #$00
                     STA M03D1
                     RTS
L079B                LDA M03D1
                     BEQ L07A1
                     RTS
L07A1                LDA #$01
                     STA M03D1
                     LDA M03CA
                     STA M03D0
                     LSR A
                     CLC
                     ADC #$71
                     STA ZD6
                     LDA #$83
                     STA ZD7
                     LDA #$01
                     STA M03D2
                     INC M0286
                     LDA M0286
                     CMP #$0F
                     BNE L07CA
                     LDA #$00
                     STA M0286
L07CA                LDA #$08
                     STA M02A4
                     RTS


L07E0                JSR L0E20
                     LDA #$00
                     STA VIASHIFTREG
                     RTS

L07FD                JMP L0907
L0800                JSR L0980      
                     JSR L09D0
L0806                JSR L0930
                     LDY M0280
L080C                LDX SCRD1100,Y
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
L082B                STA ZFB
                     STA Z0A,X
                     JMP L0840
L0832                DEC ZFB
                     DEC Z0A,X
                     LDA ZFB
                     CMP #$FF
                     BNE L0840
                     DEC ZFC
                     DEC Z0B,X
L0840                LDA M0340,X
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
L087C                JMP L08F0
                     NOP
L0880                LDA ZFC
                     AND #$03
                     STA M03D7
                     LDA ZFB
                     STA M03D6
L088C                SEC
                     LDA M03D6
                     SBC #$28
                     STA M03D6
                     BCS L089A
                     DEC M03D7
L089A                CMP #$28
                     BCS L088C
                     LDA M03D7
                     BNE L088C
                     CLC
                     ADC #$02
                     STA M03D6
                     LDA M03CA
                     LSR A
                     SEC
                     SBC M03D6
                     BPL L08B5
                     EOR #$FF
L08B5                ASL A
                     ASL A
                     NOP
                     NOP
                     NOP
                     NOP
                     JSR L09F0
                     ADC SCRD1200+$E0,Y
                     NOP
                     NOP
                     BCS L08F0
                     INC M03D4
                     LDY #$00
L08CA                LDA M03F1,Y
                     BPL L08D8
                     INY
                     INY
L08D1                CPY #$06
                     BCC L08CA
                     JMP L08F0
L08D8                SEI
                     CLC
                     LDA ZFB
                     ADC #$7A
                     STA M03F0,Y
                     BCC L08E5
                     INC ZFC
L08E5                LDA ZFC
                     STA M03F1,Y
                     CLI
                     INC M03DD
                     NOP
                     NOP
L08F0                LDY M03D5
                     LDA #$08
                     STA M03C4
L08F3                LDA #$00
                     STA M03C5
L08FD                DEC M03C5
                     BNE L08FD
                     DEC M03C4
                     BNE L08FD
L0907                INY
                     TYA
                     AND #$3F
                     CMP #$28
                     BNE L0918
                     LDA #$04
                     EOR M03C1
                     STA M03C1
                     RTS
L0918                JMP L080C


L0930                JSR L09B0
                     LDA #$28
                     STA ZFB
                     LDA #$80
                     STA ZFC
                     LDX #$17
                     NOP
                     NOP
                     NOP
L0940                LDA #$20
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
L0957                STA ZFB
                     DEX
                     BNE L0940
                     RTS
L095D                LDA M03C0
                     CMP #$28
                     BNE L096D
                     LDA M03C6
                     EOR #$FF
                     STA M03C0
                     RTS
L096D                STA M03C6
                     LDA #$28
                     STA M03C0
                     LDA #$40
                     EOR M0280
                     STA M0280
                     RTS


L0980                LDX #$00
                     LDY M03DA
L0985                LDA SCRD1000,X
                     CLC
                     ADC SCRD1200+$B0,Y
                     STA Z0A,X
                     LDA SCRD1000+$01,X
                     STA Z0B,X
                     BCC L0997
                     INC Z0B,X
L0997                INX
                     INX
                     CPX #Z50
                     BCC L0985
                     INC M03DA
                     LDA SCRD1200+$B1,Y
                     BEQ L09A6
                     RTS
L09A6                LDA #$01
                     STA M03DA
                     RTS


L09B0                LDA VIAPB
                     AND #$20
                     BNE L09B0
                     RTS


L09C0                LDA VIAPB
                     AND #$20
                     BEQ L09C0
                     RTS


L09D0                LDX #$00
                     LDY #$00
L09D4                LDA SCRD1000+Z50,X
                     STA M0340,Y
                     INY
                     INY
                     INX
                     CPX #$29
                     BCC L09D4
                     RTS


L09F0                PHA
                     LDA M03C8
                     AND #$0F
                     TAY
                     PLA
                     INC M03C8
                     RTS

L09FD                JSR L0A56
                     DEC M03E0
                     BNE L0A0E
                     LDA M03E1
                     STA M03E0
                     JSR L0580
L0A0E                DEC M03E2
                     BNE L0A1C
                     LDA M03E3
                     STA M03E2
                     JSR L0600
L0A1C                DEC M03E4
                     BNE L0A2A
                     LDA M03E5
                     STA M03E4
                     JSR L0B06
L0A2A                JSR L0780
                     JSR L0A60
                     LDA M03E6
                     CMP #$10
                     BCS L0A3A
                     JSR L0F30
L0A3A                DEC M03E6
                     BNE L0A48
                     LDA M03E7
                     STA M03E6
                     JSR L0F70
L0A48                JSR L0C93
                     JSR L0BE0
                     JSR L17A0
                     JMP CRSRBLNK 

L0A56                JSR L163C
                     JSR L0550
                     JSR L16EA
                     RTS


L0A60                LDX #$20
                     TXA
L0A63                STA $8000,X
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
L0A7B                LDA #$6C
                     STA $8000,X
                     LDA #ZFC
                     STA $8001,X
                     INX
                     INX
                     INX
                     DEY
                     BNE L0A7B
L0A8B                RTS

L0A90                LDA M03CB
                     BEQ L0A96
                     RTS
L0A96                LDA M0287
                     BNE L0AE3
                     SED
                     LDA M0286
                     ASL A
                     PHA
                     TAX
                     LDA SCRD1200+$F0,X
                     CLC
                     ADC M033C
                     STA M033C
                     LDA SCRD1200+$F1,X
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
                     LDA SCRD1200+$F0,Y
                     PHA
                     JSR L0CB6
                     PLA
                     JSR L0CB2
                     LDA SCRD1200+$F1,Y
                     BEQ L0ADD
                     JSR L0CB6
L0ADD                LDA #$10
L0ADF                STA M0287
L0AE2                RTS
L0AE3                DEC M0287
                     BNE L0ADF+$01  ; XXX bug here?
                     LDY #$10
                     LDX M03DC
                     JSR L0FB8
                     LDA #$FF
                     STA M03DC
                     LDA #$00
                     STA M03CC
                     STA M03DD
                     RTS


L0B00                JMP L0B90


L0B06                LDX #$00
L0B08                LDA M03F1,X
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
                     NOP
                     NOP
                     JMP L0B00
L0B34                LDA Z6E
                     CLC
                     ADC #$28
                     BCC L0B40
                     INC Z6F
                     INC M03F1,X
L0B40                STA Z6E
                     STA M03F0,X
                     LDA (Z6E),Y
                     CMP #$20
                     BNE L0B6C
                     LDA Z6E
                     CMP #$C0
                     BCC L0B57
                     LDA Z6F
                     CMP #$83
                     BCS L0B60
L0B57                LDA #$24
                     STA (Z6E),Y
                     JMP L0B00
                     NOP
                     NOP
L0B60                LDA #$2A
                     STA (Z6E),Y
                     LDA #$00
                     STA M03F8,X
                     JMP L0B00
L0B6C                CMP #$60
                     BEQ L0B60
                     CMP #$47
                     BEQ L0BA0
                     CMP #$48
                     BEQ L0BA0
                     CMP #$A0
                     BEQ L0B60
                     LDA Z6E
                     CMP #$98
                     BCC L0B8B
                     LDA Z6F
                     CMP #$83
                     BCC L0B8B
                     JMP L0DA0
L0B8B                LDA #$01
                     STA M03F1,X
L0B90                INX
                     INX
                     CPX #$06
                     BCC L0B97
                     RTS
L0B97                JMP L0B08

L0BA0                TYA
                     PHA
                     LDY M03D8
                     LDA $F694,Y
                     INC M03D8
                     CMP #$50
                     BCC L0BB8
                     CMP #$A0
                     BCC L0BC8
                     LDY #$2A
                     JSR L065C
L0BB8                LDA #$00
                     STA M03F8,Y
                     LDY #$00
                     LDA #$2A
                     STA (Z6E),Y
L0BC3                PLA
                     TAY
                     JMP L0B90
L0BC8                LDY #$2A
                     JSR L065C
                     JMP L0BC3

L0BE0                LDA M03C7
                     BNE L0BE6
L0BE5                RTS
L0BE6                DEC M0289
                     BNE L0BE5
                     LDA #$01
                     STA M03DB
                     JMP L0DAD

L0C00                TXA
                     PHA
                     TYA
                     PHA
                     LDY #$00
                     LDA ZFC
                     CMP #$83
                     BCC L0C1B
                     LDA ZFB
                     CMP #$47
                     BCC L0C1B
                     LDA #$01
                     STA M03C7
                     LDX #$03
                     BNE L0C1D
L0C1B                LDX ZB3
L0C1D                DEX
                     TXA
                     ORA M03C1
                     ASL A
                     ASL A
                     ASL A
                     ASL A
                     TAX
                     INX
                     JSR L09B0
L0C2B                LDA SCRD1200,X  ; animate PLAV invader one frame
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
L0C44                PLA
                     TAY
                     PLA
                     TAX
                     RTS


L0C50                LDA #$93
                     JSR BSOUT
                     JSR L09B0
                     LDX #$00
                     LDA #$60
L0C5C                STA $83C0,X
                     INX
                     CPX #$28
                     BNE L0C5C
                     JSR L0C93
                     JMP L0A60


L0C78                JSR L0CE0
                     ASL A
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
L0C92                CLD
L0C93                TXA
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


L0CB2                LSR A
                     LSR A
                     LSR A
                     LSR A
L0CB6                AND #$0F
                     ORA #$30
                     STA $8006,X
                     DEX
                     RTS


L0CC0                JSR L0CB2
                     LDA M033D
                     CMP #$15
                     BCS L0CCB
L0CCA                RTS
L0CCB                NOP
                     LDA M0288
                     BNE L0CCA
                     INC M03DB
                     JSR L0A60
                     LDA #$FF
                     STA M0288
                     RTS


L0CE0                PHA
                     TXA
                     PHA
                     LDX #$00
L0CE5                LDA SCRD1300+$10,X
                     BNE L0CF1
                     PLA
                     TAX
                     PLA
                     ASL A
                     ASL A
                     ASL A
                     RTS
L0CF1                STA $8000,X
                     INX
                     BNE L0CE5
                     RTS


L0D00                NOP
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
                     NOP
                     LDX M03D8
                     CLD
                     EOR ZCB,X
                     CMP #$A0
                     BCC L0D20
                     JMP L065C


L0D20                LDX #$00
L0D22                LDA ZD6
                     CLC
                     ADC #$2A
                     TAY
                     LDA ZD7
                     BCC L0D2E
                     BCC L0D2E
L0D2E                CMP M03F1,X
                     BNE L0D39
                     TYA
                     CMP M03F0,X
                     BEQ L0D40
L0D39                INX
                     INX
                     CPX #$06
                     BCC L0D22
                     RTS
L0D40                LDA #$00
                     STA M03F8,X
                     LDY M03D8
                     LDA L0D78,Y
                     CMP #$80
                     BCC L0D58
                     LDY #$2A
                     JMP L065C
                     NOP
                     NOP
                     NOP
                     NOP
L0D58                RTS




L0D60                LDA #$FF
                     STA ZFB
                     LDA #$82
                     STA ZFC
                     JSR L0D88
                     LDA #$06
                     STA ZFB
                     LDA #$83
                     STA ZFC
                     JSR L0D88
                     LDA #$0E
L0D78                STA ZFB
                     JSR L0D88
                     LDA #$15
                     STA ZFB
                     JMP L0D88


L0D88                LDX #$00
                     LDY #$00
                     LDA SCRD1200+$82,X
L0D8F                LDY SCRD1200+$83,X
                     STA (ZFB),Y
                     INX
                     INX
                     LDA SCRD1200+$82,X
                     BNE L0D8F
                     RTS


L0D9D                JMP L0B90


L0DA0                LDA M0283
                     BEQ L0D9D
                     LDA #$01
                     STA M03F1,X
                     STA M03F8,X
L0DAD                LDA #$00
                     STA M0283
                     LDA ZD7
                     BPL L0DB9
                     JSR L0615
L0DB9                NOP
                     NOP
                     NOP
                     LDY #$02
                     STY M0281
                     LDA #$80
                     STA M0282
L0DC6                LDA M0281
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
L0DE3                JSR L09C0
                     JSR L17D9
                     DEC M0282
                     BNE L0DC6
                     LDX M03CA
                     LDA #$04
                     JSR L05B3
                     DEC M03DB
                     JSR L0A60
                     JMP L17F0


L0E00                LDA #$02
                     STA M03E1
                     STA M03E3
                     LDA #$04
                     STA M03E5
                     LDA #$06
                     STA M03E7
                     LDA #$00
                     STA M033E
                     STA M033F
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
L0E20                LDA #$00
                     STA M033C
                     STA M033D
                     STA M03C6
                     STA M03C7
                     STA M03D5
                     STA M03DA
                     STA M0288
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
L0E51                LDA #$00
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
L0E88                LDA #$00
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
                     STA L08F3+$01 ; self-modifying code
                     LDA #$FF
                     STA M03C9
                     LDA #$06
                     STA L08D1+$01 ; self-modifying code
                     LDA #$10
                     STA $E84B
                     LDA #$0F
                     STA VIASHIFTREG
                     LDA #$00
                     STA TIMR2LO
                     LDA #$02
                     STA M02A1
                     STA M02A2
                     LDA #$00
                     STA M02A4
                     RTS
; this routine exists in the original but nothing calls it
;L0ED9                STA M0286
;                     LDA #$00
;                     STA M0287
;                     LDA #$01
;                     STA M03F1
;                     STA M03F3
;                     STA M03F5
;                     RTS

L0EF0                STA M03E2
                     STA M02A0
                     RTS

L0F00                LDA M03DB
                     BNE L0F08
                     JMP L0FB0
L0F08                LDA #$00
                     STA M0284
                     STA M0285
L0F10                DEC M0284
                     BNE L0F10
                     DEC M0285
                     BNE L0F10
                     JSR L0E88
                     LDA IV0090
                     CMP #$50
                     BEQ L0F25
                     RTS
L0F25                JSR L0520
                     JMP L19F2


L0F30                LDX #$00
L0F32                LDA $8028,X
                     CMP #$20
                     BEQ L0F3A
                     RTS
L0F3A                INX
                     CPX #$51
                     BNE L0F32
                     LDA M03DC
                     BMI L0F45
                     RTS
L0F45                LDA M03DD
                     CMP #$18
                     BCS L0F4D
L0F4C                RTS
L0F4D                LDA M03CE
                     CMP #$08
                     BCC L0F4C
                     LDA M0286
                     AND #$01
                     BNE L0F62
                     NOP
                     LDA #$01
                     LDX #$00
                     BEQ L0F66
L0F62                LDA #$FF
                     LDX #$22
L0F66                STA M03DE
                     STX M03DC
                     RTS

L0F6C                RTS

L0F70                LDA M03DC
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
L0F90                TAX
                     BEQ L0F96
                     DEX
                     BNE L0F97
L0F96                INX
L0F97                LDY #$10
                     JSR L0FB8
                     LDA #$FF
                     STA M03DC
                     LDA #$00
                     STA M03DD
                     RTS


L0FB0                JSR L0510
                     JMP L18C6


L0FB8                LDA SCRD1200+$C0,Y
                     BNE L0FBE
                     RTS
L0FBE                STA $8028,X
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

L0FD8                JMP L0A90

L1600                LDY #$00
L1602                LDA (ZFB),Y
                     CMP #$FF
                     BNE L1609
                     RTS
L1609                CMP #$20
                     BCC L1610
                     JSR L1680
L1610                JSR BSOUT 
                     INY
                     BNE L1602
                     RTS


L1617                LDX #$00
                     TXS
                     JSR L1800
                     JMP L19E6


L1620                LDY #$00
                     LDX #$00
L1624                LDA SCRD1500+$80,X
                     BNE L162A
                     RTS
L162A                STA (ZFB),Y
                     LDA SCRD1500+$C0,X
                     CLC
                     ADC ZFB
                     BCC L1636
                     INC ZFC
L1636                STA ZFB
                     INX
                     BNE L1624
                     RTS


L163C                LDA M02A0
                     BEQ L1652
                     DEC M02A0
                     BMI L1647
                     RTS
L1647                LDA M03CE
                     SEC
                     SBC #$01
                     ASL A
                     STA M02A0
                     RTS
L1652                DEC M02A1
                     BEQ L1661
                     LDX M02A2
                     LDA SCRD1300+$C0,X
                     STA TIMR2LO
                     RTS
L1661                LDA #$00
                     STA TIMR2LO
                     DEC M02A2
                     BNE L1670
                     LDA #$04
                     STA M02A2
L1670                LDA #$FF
                     STA M02A0
                     LDA #$03
                     STA M02A1
                     RTS

L1680                PHA         ; Delay loop (count down from $2000)
                     LDA #$20
                     STA M0293
                     LDA #$00
                     STA M0292
L168B                DEC M0292
                     BNE L168B
                     DEC M0293
                     BNE L168B
                     PLA
                     RTS

L16A0                PHA
                     LDA #$02
                     STA M0294
                     LDA #$00
                     STA M0293
                     STA M0292
L16AE                DEC M0292
                     BNE L16AE
                     DEC M0293
                     BNE L16AE
                     DEC M0294
                     BNE L16AE
                     PLA
                     RTS


L16C0                LDA #$00     ; Clear the screen
                     STA ZFB
                     LDA #$80
                     STA ZFC
                     LDX #$04
                     LDY #$28
                     LDA #$20
L16CE                STA (ZFB),Y
                     INY
                     BNE L16CE
                     INC ZFC
                     DEX
                     BNE L16CE
                     RTS


L16E0                LDX M03D9
                     LDA SCRD1300+$D7,X
                     STA TIMR2LO
                     RTS

L16EA                LDX M02A4
                     BNE L16F0
                     RTS
L16F0                DEC M02A4
                     LDA SCRD1300+$E7,X
                     STA TIMR2LO
                     RTS


L1700                JSR L07E0
                     LDA Z8F
                     STA M03D8
                     JSR L0C50
                     LDA #$00
                     JSR L0C78
                     JSR L0D60
                     JSR L0800
L1717                JSR L0806
                     LDA M03C7
                     BNE L1722
                     JMP L1717
L1722                RTS



L1728                LDA Z8F
                     AND #$3F
                     TAY
                     INC Z8F
                     LDA SCRD1300+$80,Y
                     CMP #$60
                     BCS L173C
                     LDA #$7F
                     BCC L1746
L173C                CMP #$A0
                     BCC L1744
                     LDA #$BF
                     BCS L1746
L1744                LDA #$FF
L1746                LDX SCRD1200+$01,Y
                     BMI L174D
                     AND #$FE
L174d                JMP L058D


; hardware interrupt handler
L1750                DEC M03E0
                     BNE L175E
                     LDA M03E1
                     STA M03E0
                     JSR L1728
L175E                DEC M03E2
                     BNE L176C
                     LDA M03E3
                     STA M03E2
                     JSR L0600
L176C                DEC M03E4
                     BNE L177A
                     LDA M03E5
                     STA M03E4
                     JSR L0B06
L177A                JSR L0780
                     JSR L0A60
                     JSR L0C93
                     JSR L17A0
                     JMP L19A0


L17A0                LDX #$00
L17A2                LDA SCRD1300+$70,X
                     BEQ L17B0
                     STA $800F,X
                     INX
                     JMP L17A2
                     NOP
                     NOP
L17B0                LDX #$11
                     LDA M033E
                     JSR L0CB6
                     LDA M033E
                     JSR L0CB2
                     LDA M033F
                     JSR L0CB6
                     LDA M033F
                     JMP L0CB2


L17D0                LDA #$00
                     STA VIASHIFTREG
                     LDA M03F1
                     RTS


L17D9                JSR L09B0
                     JSR L17E0
                     RTS


L17E0                LDA M0282
                     AND #$01
                     BEQ L17E9
                     LDA #$FF
L17E9                STA TIMR2LO
                     RTS


L17F0                JSR L17D0
                     JMP L0F00


L1800                JSR L16C0      ; PLAV INVADER TRAINER SEQUENCE
                     LDA #<SCRD1400
                     STA ZFB
                     LDA #>SCRD1400
                     STA ZFC
                     JSR L1600
                     LDA #$46
                     STA ZFB
                     LDA #$81
                     STA ZFC
                     JSR L1620
                     LDA #<SCRD1400+$38
                     STA ZFB
                     LDA #>SCRD1400
                     STA ZFC
                     JSR L1600
                     JSR L16A0
                     NOP
                     LDA #$74
                     STA ZFB
                     LDA #$80
                     STA ZFC
                     LDX #$11
                     LDA #$03
                     STA ZB3
L1836                JSR L0C00
                     LDA M03C1
                     EOR #$04
                     STA M03C1
                     JSR L1680
                     DEX         ; decrement # moves for PLAV invader
                     BEQ L1850    
                     DEC ZFB
                     BNE L1836
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
L1850                LDA #$16
                     STA SCRD1200+$26
                     STA SCRD1200+$66
                     LDX #$11
L185A                JSR L0C00
                     LDA M03C1
                     EOR #$04
                     STA M03C1
                     JSR L18B0
                     DEX
                     BEQ L186F
                     INC ZFB
                     BNE L185A
L186F                JSR L18C0
                     STA SCRD1200+$26
                     STA SCRD1200+$66
                     LDX #$11
L187A                JSR L0C00
                     LDA M03C1
                     EOR #$04
                     STA M03C1
                     JSR L1680
                     DEX
                     BEQ L1890
                     DEC ZFB
                     BNE L187A
                     NOP
L1890                JSR L16A0
                     LDA #$20
                     STA SCRD1200+$26
                     STA SCRD1200+$66
                     LDA #$04
                     STA ZB3
                     LDA #$00
                     STA M03C1
                     JSR L0C00
                     LDA #$19
                     STA $808C
                     JMP L16A0


L18B0                JSR L1680
                     LDY #$28
                     LDA #$20
                     STA (ZFB),Y
                     LDY #$00
                     RTS


L18C0                JSR L16A0
                     LDA #$19
                     RTS


L18C6                LDA M033D
                     CMP M033F
                     BEQ L18D2
                     BCS L18DA
                     BCC L18E9
L18D2                LDA M033C
                     CMP M033E
                     BCC L18E6
L18DA                LDA M033C
                     STA M033E
                     LDA M033D
                     STA M033F
L18E6                JSR L17A0
L18E9                LDA #<SCRD1350
                     STA ZFB
                     LDA #>SCRD1350
                     STA ZFC
                     JSR L1600
                     JSR L16A0
L18F7                JSR GET
                     BNE L18F7
                     JMP L19DB

L1900                JSR L16C0
                     LDA #<SCRD1500
                     STA ZFB
                     LDA #>SCRD1500
                     STA ZFC
                     JSR L1600
                     JSR L16A0
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     NOP
                     LDA #$4B
                     STA ZFB
                     LDA #$80
                     STA ZFC
                     LDX #$13
                     LDA #$03
                     STA ZB3
                     LDA #$00
                     STA M03C1
L192B                JSR L0C00
                     LDA M03C1
                     EOR #$04
                     STA M03C1
                     JSR L1680
                     DEX
                     BEQ L1940
                     DEC ZFB
                     BNE L192B
L1940                NOP
                     NOP
                     NOP
                     LDA #$B3
                     STA Z6E
                     LDA #$80
                     STA Z6F
                     LDY #$00
L194D                LDA #$20
                     STA (Z6E),Y
                     LDA Z6E
                     CLC
                     ADC #$28
                     BCC L195A
                     INC Z6F
L195A                STA Z6E
                     LDA (Z6E),Y
                     CMP #$20
                     BNE L1970
                     LDA #$24
                     STA (Z6E),Y
                     JSR L1680
                     JMP L194D
L1970                LDA #$2A
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


L19A0                JSR GET
                     BNE L19A8
                     JMP CRSRBLNK
L19A8                JSR L16C0
                     JSR L0510
                     LDX #$00
L19B0                LDA SCRD1300+$18,X
                     STA $8198,X
                     INX
                     CPX #$16
                     BNE L19B0
L19BB                JSR GET
                     BEQ L19BB
                     JSR L16C0
                     LDX #$00
L19C5                LDA SCRD1300+$2E,X
                     STA $819C,X
                     INX
                     CPX #$0E
                     BNE L19C5
                     JSR L16A0
                     JMP L0490


L19D8                JSR L0E00
L19DB                JSR L0520
                     BNE L19E3

L19E0                JSR L1900
L19E3                JMP L1617


L19E6                JSR L0530 ; set up interrupts
                     JSR L1700
                     JSR L0520
                     JMP L19E0

L19F2                LDX #$FF
                     TXS
                     NOP
                     JSR L0520
                     JMP L19E0


; BRK interrupt handler
L19F6                JSR L0520
                     JMP L19E0

; character/screen data
SCRD1000
 .byte $fc,$81,$f8,$81,$f4,$81,$f0,$81,$ec,$81,$e8,$81,$e4,$81,$e0,$81
 .byte $84,$81,$80,$81,$7c,$81,$78,$81,$74,$81,$70,$81,$6c,$81,$68,$81
 .byte $0c,$81,$08,$81,$04,$81,$00,$81,$fc,$80,$f8,$80,$f4,$80,$f0,$80
 .byte $94,$80,$90,$80,$8c,$80,$88,$80,$84,$80,$80,$80,$7c,$80,$78,$80
 .byte $1c,$80,$18,$80,$14,$80,$10,$80,$0c,$80,$08,$80,$04,$80,$00,$80
 .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
 .byte $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
 .byte $03,$03,$03,$03,$03,$03,$03,$03,$ca,$d0,$e4,$86,$54,$60,$a9,$01
 .byte $85,$54,$60,$ad,$40,$e8,$29,$20,$d0,$f9,$60,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

SCRD1100
 .byte $00,$02,$04,$06,$08,$0a,$0c,$0e,$10,$12,$14,$16,$18,$1a,$1c,$1e
 .byte $20,$22,$24,$26,$28,$2a,$2c,$2e,$30,$32,$34,$36,$38,$3a,$3c,$3e
 .byte $40,$42,$44,$46,$48,$4a,$4c,$4e,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $0e,$0c,$0a,$08,$06,$04,$02,$00,$1e,$1c,$1a,$18,$16,$14,$12,$10
 .byte $2e,$2c,$2a,$28,$26,$24,$22,$20,$3e,$3c,$3a,$38,$36,$34,$32,$30
 .byte $4e,$4c,$4a,$48,$46,$44,$42,$40,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $20,$20,$6c,$fc,$20,$20,$20,$60,$e1,$e0,$e0,$e0,$60,$60,$00,$00
 .byte $20,$20,$20,$fe,$7b,$20,$20,$60,$60,$e0,$e0,$e0,$61,$60,$00,$00
 .byte $7f,$fe,$6c,$7f,$e2,$7b,$ff,$60,$7f,$fc,$fe,$fe,$ff,$60,$00,$00
 .byte $6c,$7f,$fe,$62,$6c,$6c,$20,$60,$e1,$fc,$fc,$62,$61,$60,$00,$00
 .byte $20,$20,$20,$20,$20,$20,$20,$60,$60,$60,$60,$60,$60,$60,$00,$00
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

SCRD1200
 .byte $00,$20,$20,$20,$20,$20,$20,$ff,$e3,$7f,$20,$20,$ff,$f9,$7f,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$fc,$99,$fe,$20,$20,$fb,$20,$ec,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$e9,$f2,$df,$20,$20,$18,$20,$18,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$ff,$e3,$7f,$20,$20,$e1,$f9,$61,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$62,$99,$62,$20,$20,$ec,$62,$fb,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$e9,$f2,$df,$20,$20,$3c,$20,$3e,$20
 .byte $00,$20,$20,$20,$20,$20,$20,$4d,$5d,$2f,$20,$20,$2f,$5d,$4d,$20
 .byte $47,$48,$a0,$01,$a0,$02,$a0,$28,$a0,$29,$a0,$2a,$a0,$2b,$a0,$50
 .byte $a0,$51,$a0,$52,$a0,$53,$a0,$78,$a0,$7b,$00,$00,$00,$00,$00,$00
 .byte $00,$00,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 .byte $05,$2d,$7d,$a5,$a5,$a5,$cd,$cd,$f5,$00,$24,$24,$24,$24,$24,$24
 .byte $20,$e9,$d1,$d1,$d1,$df,$20,$20,$4a,$4b,$20,$4a,$4b,$20,$00,$00
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00
 .byte $ff,$ff,$ff,$ff,$10,$ff,$ff,$d0,$ff,$ff,$00,$ff,$ff,$ff,$ff,$00
 .byte $50,$00,$00,$01,$50,$00,$50,$01,$00,$01,$00,$01,$50,$00,$00,$03

SCRD1300
 .byte $00,$01,$00,$01,$50,$00,$50,$01,$00,$01,$50,$00,$00,$01,$00,$00
 .byte $13,$03,$0f,$12,$05,$00,$20,$20,$10,$15,$13,$08,$20,$01,$0e,$19
 .byte $20,$0b,$05,$19,$20,$14,$0f,$20,$13,$14,$01,$12,$14,$2e,$10,$0c
 .byte $01,$19,$20,$10,$0c,$01,$19,$05,$12,$20,$31,$20,$20,$20,$20,$20
 .byte $01,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$02,$01,$01,$01,$01
 
SCRD1350
 .byte $13,$11,$11,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$47,$41,$4d,$45,$20,$4f,$56,$45,$52,$ff,$ed,$4c,$9b,$14
 .byte $08,$09,$07,$08,$00,$20,$20,$20,$1b,$20,$4f,$16,$90,$ef,$b0,$da
 .byte $00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80,$80,$80,$80,$f0,$f0
 .byte $f0,$f0,$f0,$f0,$00,$00,$00,$00,$80,$80,$80,$80,$80,$80,$80,$80
 .byte $80,$f0,$f0,$f0,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$80,$80,$80
 .byte $80,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$80,$80,$80,$80,$80
 .byte $00,$ff,$f0,$d8,$c0,$30,$ef,$68,$90,$8b,$85,$7d,$72,$65,$55,$50
 .byte $4a,$50,$55,$62,$6d,$78,$82,$88,$00,$00,$7a,$68,$56,$44,$32,$28
 .byte $10,$15,$28,$36,$40,$48,$4d,$50,$00,$00,$20,$00,$10,$00,$18,$20
 .byte $58,$2c,$59,$29,$00,$58,$29,$2c,$59,$00,$00,$2c,$58,$2c,$59,$00

SCRD1400
 .byte $13,$11,$11,$11,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$1d,$1d,$1d,$50,$4c,$41,$56,$11,$9d,$9d,$9d,$9d,$9d,$9d
 .byte $9d,$9d,$9d,$11,$53,$50,$41,$43,$45,$20,$49,$4e,$56,$41,$44,$45
 .byte $52,$53,$0d,$11,$11,$11,$11,$ff,$0d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$1d,$1d,$1d,$1d,$1d,$2e,$2e,$2e,$2e,$2e,$2e,$2e,$20,$3f
 .byte $4d,$59,$53,$54,$45,$52,$59,$0d,$11,$11,$1d,$1d,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$2e,$2e,$2e,$2e,$2e,$2e,$2e,$20 
 .byte $33,$30,$20,$50,$4f,$49,$4e,$54,$53,$0d,$11,$11,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$2e,$2e,$2e,$2e,$2e,$2e
 .byte $2e,$20,$32,$30,$20,$50,$4f,$49,$4e,$54,$53,$0d,$11,$11,$1d,$1d
 .byte $1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$2e,$2e,$2e,$2e
 .byte $2e,$2e,$2e,$20,$31,$30,$20,$50,$4f,$49,$4e,$54,$53,$0d,$11,$11
 .byte $1d,$1d,$1d,$1d,$54,$4f,$50,$20,$31,$35,$30,$30,$20,$50,$4f,$49
 .byte $4e,$54,$53,$20,$46,$4f,$52,$20,$45,$58,$54,$52,$41,$20,$42,$41
 .byte $53,$45,$2e,$ff,$11,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$11,$53
 .byte $50,$41,$43,$45,$20,$49,$4e,$56,$41,$44,$45,$52,$53,$0d,$11,$11

SCRD1500
 .byte $13,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$1d,$1d,$1d,$1d,$1d 
 .byte $1d,$1d,$1d,$1d,$1d,$4b,$45,$59,$42,$4f,$41,$52,$44,$20,$43,$43
 .byte $4f,$4d,$4d,$41,$4e,$44,$53,$11,$11,$11,$9d,$9d,$9d,$9d,$9d,$9d
 .byte $9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$12,$34,$92,$2d,$4d,$4f,$56
 .byte $45,$20,$4c,$45,$46,$54,$0d,$11,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$1d,$1d,$1d,$12,$36,$92,$2d,$4d,$4f,$56,$45,$20,$52,$49
 .byte $47,$48,$54,$0d,$11,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
 .byte $1d,$1d,$12,$41,$92,$2d,$46,$49,$52,$45,$20,$42,$45,$41,$4d,$ff
 .byte $2a,$2a,$2a,$13,$03,$0f,$12,$05,$01,$04,$16,$01,$0e,$03,$05,$14 
 .byte $01,$02,$0c,$05,$2a,$2a,$2a,$e9,$d1,$d1,$d1,$df,$4a,$4b,$4a,$4b
 .byte $e9,$f2,$df,$18,$18,$62,$99,$62,$ec,$62,$fb,$ff,$e3,$7f,$ff,$f9
 .byte $7f,$00,$2e,$2e,$2e,$2e,$2e,$20,$3f,$4d,$59,$53,$54,$45,$52,$59
 .byte $01,$01,$02,$01,$01,$01,$01,$02,$01,$01,$01,$01,$01,$01,$02,$01 
 .byte $01,$01,$01,$02,$01,$01,$60,$01,$01,$01,$01,$24,$01,$02,$01,$4d
 .byte $01,$01,$26,$02,$4e,$01,$01,$26,$01,$01,$4e,$01,$01,$26,$01,$01
 .byte $1d,$1d,$1d,$2e,$2e,$2e,$2e,$2e,$2e,$2e,$20,$32,$30,$20,$50,$4f

SCRD1C00
 .byte $20,$20,$20,$2a,$20,$08,$0f,$17,$20,$14,$0f,$20,$10,$12,$0f,$04
 .byte $15,$03,$05,$20,$13,$0f,$15,$0e,$04,$20,$05,$06,$06,$05,$03,$14
 .byte $13,$20,$2a,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$90,$81,$92,$81,$8c,$8c
 .byte $85,$8c,$a0,$90,$8f,$92,$94,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$31,$20,$32
 .byte $20,$33,$20,$34,$20,$35,$20,$36,$20,$37,$20,$38,$20,$39,$20,$b0
 .byte $20,$b1,$20,$b2,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$70,$62,$40,$62,$40,$62,$40,$62,$40,$62,$40,$62
 .byte $40,$62,$40,$62,$40,$62,$40,$62,$40,$62,$40,$62,$6e,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$0b,$20,$0c,$5d,$20,$20,$20,$07,$0e,$04,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$6d,$f9,$40,$f9,$40,$f9,$40,$f9,$40,$f9,$40,$f9

SCRD1D00
 .byte $40,$f9,$40,$f9,$40,$f9,$40,$f9,$40,$f9,$40,$f9,$7d,$20,$20,$4e
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$01,$20,$02
 .byte $20,$03,$20,$04,$20,$05,$20,$06,$20,$07,$20,$08,$20,$09,$20,$0a
 .byte $4e,$67,$20,$5d,$63,$63,$63,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$67,$20,$67,$20,$5d,$20,$66,$19,$0f
 .byte $15,$12,$20,$10,$05,$14,$20,$20,$20,$66,$66,$66,$66,$66,$66,$66
 .byte $66,$66,$66,$66,$66,$66,$66,$66,$20,$20,$03,$02,$32,$64,$64,$4e
 .byte $20,$67,$20,$5d,$20,$66,$20,$20,$4f,$63,$63,$50,$20,$20,$20,$20
 .byte $20,$2a,$03,$0f,$0e,$0e,$05,$03,$14,$20,$03,$02,$32,$20,$20,$66
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$4e,$20,$5d,$20,$66,$20,$59
 .byte $20,$5c,$5c,$5c,$54,$20,$20,$20,$20,$20,$14,$0f,$20,$19,$0f,$15
 .byte $12,$20,$01,$0d,$10,$20,$20,$66,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$4d,$20,$5d,$20,$66,$20,$6d,$72,$40,$40,$72,$7d,$20,$20,$20
 .byte $20,$20,$14,$08,$12,$0f,$15,$07,$08,$20,$35,$30,$2d,$20,$20,$66
 .byte $20,$20,$20,$20,$20,$20,$20,$12,$20,$4e,$20,$5d,$20,$66,$67,$63

SCRD1E00
 .byte $63,$63,$63,$63,$63,$65,$20,$20,$20,$20,$35,$30,$30,$0b,$20,$0f
 .byte $08,$0d,$20,$20,$20,$20,$20,$66,$20,$35,$30,$2d,$35,$30,$30,$0b
 .byte $20,$4d,$20,$5d,$20,$66,$48,$7b,$62,$20,$62,$20,$2e,$47,$20,$20
 .byte $20,$20,$12,$05,$13,$09,$13,$14,$05,$12,$20,$20,$20,$20,$20,$66
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$4e,$20,$5d,$20,$66,$20,$45
 .byte $45,$45,$45,$45,$45,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$66,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$4d,$20,$5d,$20,$66,$20,$20,$1e,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$67,$4d,$20,$20,$20,$20,$20,$70,$40,$40,$40,$40,$40,$40,$6e
 .byte $20,$20,$03,$02,$32,$20,$20,$20,$20,$67,$20,$5d,$20,$66,$20,$20
 .byte $5d,$20,$20,$20,$20,$20,$20,$20,$20,$67,$20,$4d,$20,$20,$20,$20
 .byte $5d,$01,$15,$04,$09,$0f,$20,$5d,$64,$64,$64,$64,$64,$64,$64,$64
 .byte $64,$7a,$20,$5d,$20,$66,$10,$2e,$10,$0f,$12,$14,$20,$20,$20,$20
 .byte $20,$67,$20,$20,$a0,$40,$40,$40,$5d,$20,$20,$20,$20,$20,$20,$5d
 .byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$7d,$20,$66,$66,$66
 .byte $66,$66,$66,$66,$66,$66,$66,$66,$20,$67,$20,$20,$a0,$40,$40,$40

SCRD1F00
 .byte $5d,$20,$01,$0d,$10,$20,$20,$5d,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$67,$20,$4e,$20,$20,$20,$20,$6d,$40,$40,$40,$40,$40,$40,$7d
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$67,$4e,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
 .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20