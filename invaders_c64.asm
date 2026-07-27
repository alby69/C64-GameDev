;
; ****************************************************************************
; INVADERS -- Commodore 64 Port
; Based on original PET Invaders disassembly by Dave McMurtrie
; (dave@commodore.international, August 2023)
; C64 Adaptation by: OpenCode
; ****************************************************************************
;
; COSA CAMBIA RISPETTO AL PET:
;   Screen  $8000-$83FF  -> $0400-$07E7  (C64 = PET - $7C00)
;   Charset ROM PET      -> charset PET caricato a $3800
;   IRQ     $0090-$0091  -> $0314-$0315
;   NMI     $0092-$0093  -> $0318-$0319 (BRK handler)
;   Suono   VIA $E8xx    -> SID $D4xx
;   Input   PIA $E81x    -> CIA1 $DC00-$DC01
;   RNG     Kernal PET   -> SID $D41B
;
; ASSEMBLATORE: xa
;   xa -M invaders_c64.asm -o invaders64.prg
;   (-M abilita i due punti nei commenti)
;
; ESECUZIONE:
;   LOAD"INVADERS64.PRG",8,1
;   SYS 2062
; ****************************************************************************

; ============================================================================
; BASIC LOADER C64
; ============================================================================
* = $0801
.word $080B, 10        ; Line 10
.byte $9E              ; SYS
.asc " 2062", $00      ; SYS 2062 -> $080E
.byte $00, $00

; ============================================================================
; KERNAL C64
; ============================================================================
BSOUT      = $FFD2
GET        = $FFE4
KERNAL_IRQ = $EA31     ; Standard Kernal IRQ entry

; ============================================================================
; HARDWARE C64
; ============================================================================
CIA1_PRA   = $DC00
CIA1_PRB   = $DC01
CIA1_DDRA  = $DC02
CIA1_DDRB  = $DC03

SID_FREQ_LO1 = $D400
SID_FREQ_HI1 = $D401
SID_CTRL1    = $D404
SID_ATT_DEC1 = $D405
SID_SUST_REL1= $D406
SID_VOL      = $D418
SID_RANDOM   = $D41B

VIC_MEM     = $D018
VIC_BORDER  = $D020
VIC_BG      = $D021
VIC_RASTER  = $D012

IRQ_VEC     = $0314
NMI_VEC     = $0318

; ============================================================================
; ZERO PAGE
; ============================================================================
Z0A = $0A
Z0B = $0B
Z50 = $50
Z51 = $51
Z52 = $52
Z53 = $53
Z6E = $6E
Z6F = $6F
Z8F = $8F
ZCB = $CB
ZB3 = $B3
ZD6 = $D6
ZD7 = $D7
ZFB = $FB
ZFC = $FC

; ============================================================================
; VARIABILI PAGINA 2
; ============================================================================
M0280 = $0280
M0281 = $0281
M0282 = $0282
M0283 = $0283
M0284 = $0284
M0285 = $0285
M0286 = $0286
M0287 = $0287
M0288 = $0288
M0289 = $0289
M0292 = $0292
M0293 = $0293
M0294 = $0294
M02A0 = $02A0
M02A1 = $02A1
M02A2 = $02A2
M02A3 = $02A3
M02A4 = $02A4

; ============================================================================
; VARIABILI PAGINA 3
; ============================================================================
M033C = $033C
M033D = $033D
M033E = $033E
M033F = $033F
M0340 = $0340
M03C0 = $03C0
M03C1 = $03C1
M03C4 = $03C4
M03C5 = $03C5
M03C6 = $03C6
M03C7 = $03C7
M03C8 = $03C8
M03C9 = $03C9
M03CA = $03CA
M03CB = $03CB
M03CC = $03CC
M03CD = $03CD
M03CE = $03CE
M03D0 = $03D0
M03D1 = $03D1
M03D2 = $03D2
M03D4 = $03D4
M03D5 = $03D5
M03D6 = $03D6
M03D7 = $03D7
M03D8 = $03D8
M03D9 = $03D9
M03DA = $03DA
M03DB = $03DB
M03DC = $03DC
M03DD = $03DD
M03DE = $03DE
M03E0 = $03E0
M03E1 = $03E1
M03E2 = $03E2
M03E3 = $03E3
M03E4 = $03E4
M03E5 = $03E5
M03E6 = $03E6
M03E7 = $03E7
M03F0 = $03F0
M03F1 = $03F1
M03F2 = $03F2
M03F3 = $03F3
M03F4 = $03F4
M03F5 = $03F5
M03F8 = $03F8

; ============================================================================
; INIZIO CODICE -- $080E
; ============================================================================

; === INSTALLA CHARACTER SET PET SU C64 ===
; Strategia:
; 1. Copia il character ROM C64 da $D000 a $3800 (accedendo alla ROM via $01)
; 2. Sovrascrive i caratteri $60-$7F coi pattern PET
; 3. Punta VIC-II a $3800

START
                      ; Salva $01, abilita ROM caratteri a $D000
                      LDA $01
                      PHA
                      AND #$FB       ; Bit 2=0 -> I/O visibile, CHAR ROM a $D000
                      STA $01

                      ; Copia 2KB di character ROM da $D000 a $3800
                      LDX #$00
L_COPY_CHAR_LOOP
                      LDA $D000,X
                      STA $3800,X
                      LDA $D100,X
                      STA $3900,X
                      LDA $D200,X
                      STA $3A00,X
                      LDA $D300,X
                      STA $3B00,X
                      LDA $D400,X
                      STA $3C00,X
                      LDA $D500,X
                      STA $3D00,X
                      LDA $D600,X
                      STA $3E00,X
                      LDA $D700,X
                      STA $3F00,X
                      INX
                      BNE L_COPY_CHAR_LOOP

                      ; Ripristina $01
                      PLA
                      STA $01

                      ; Sovrascrivi caratteri PET $60-$7F ($3800+$300)
                      ; con i pattern del PET
                      LDX #$00
L_COPY_PET_CHARS
                      LDA PET_GRAPHICS_DATA,X
                      STA $3B00,X    ; $3800 + $60*8 = $3B00
                      INX
                      CPX #$00       ; 32 caratteri x 8 byte = 256, wrap to 0
                      BNE L_COPY_PET_CHARS

                      ; Configura VIC-II screen $0400 charset $3800
                      LDA #$1E       ; %0001 1110
                      STA VIC_MEM
                      ; Colori bordo nero, sfondo nero
                      LDA #$00
                      STA VIC_BORDER
                      STA VIC_BG

                      ; Inizializza Color RAM ($D800-$DBFF) con colore verde ($05)
                      ; e i primi 40 byte (riga HUD) con bianco ($01)
                      LDX #$00
L_INIT_COLOR_RAM
                      LDA #$05       ; Verde per gli invaders, bunker, ecc.
                      STA $D800,X
                      STA $D900,X
                      STA $DA00,X
                      STA $DB00,X
                      INX
                      BNE L_INIT_COLOR_RAM

                      ; Imposta i primi 40 byte (riga HUD) a bianco ($01)
                      LDX #39
L_INIT_HUD_COLOR
                      LDA #$01       ; Bianco
                      STA $D800,X
                      DEX
                      BPL L_INIT_HUD_COLOR

                      ; Inizializza SID
                      LDA #$0F
                      STA SID_VOL
                      LDA #$00
                      STA SID_FREQ_LO1
                      STA SID_FREQ_HI1
                      STA SID_CTRL1
                      LDA #$08       ; Attack/decay veloci
                      STA SID_ATT_DEC1
                      LDA #$00
                      STA SID_SUST_REL1

; === SCHERMATA "HOW TO GET SOUND" ===
; Copia i dati della schermata informativa dalla tabella PET ($1C00)
; alla memoria video C64 ($0400)
                      LDA #<SCRD1C00_DATA
                      STA Z50
                      LDA #>SCRD1C00_DATA
                      STA Z51
                      LDA #>$0400
                      STA Z53
                      LDY #$00
                      STY Z52
                      LDX #$04       ; 4 pagine (1024 byte)
L0428                 LDA (Z50),Y
                      STA (Z52),Y
                      INY
                      BNE L0428
                      INC Z51
                      INC Z53
                      DEX
                      BNE L0428

                      ; Aspetta pressione tasto
L0436                 JSR GET
                      BNE L0436
L043B                 JSR GET
                      BEQ L043B
                      LDA #$93       ; CLR/HOME
                      JSR BSOUT
                      JMP L19D8

; ============================================================================
; MAIN GAME LOOP (indirizzi convertiti PET->C64)
; ============================================================================
; MAPPA CONVERSIONE INDIRIZZI SCHERMO:
;   PET $8000 -> C64 $0400
;   PET $8006 -> C64 $0406  (punteggio)
;   PET $800F -> C64 $040F  (high score)
;   PET $8026 -> C64 $0426  (PLAV flag)
;   PET $8066 -> C64 $0466
;   PET $808C -> C64 $048C
;   PET $8098 -> C64 $0498
;   PET $8198 -> C64 $0598
;   PET $819C -> C64 $059C
;   PET $83C0 -> C64 $07C0  (bunker row)

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
                      STA L08F3_SELF+1
                      NOP
L04F4                 LDA #$04
                      STA L08D1_SELF+1
                      RTS

; ============================================================================
; INTERRUPT VECTORS (C64 $0314/$0315 invece di PET $0090/$0091)
; ============================================================================

; Game tick interrupt
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

L0580                 LDA #$FF
                      STA CIA1_PRA   ; Ripristina selezione colonne tastiera per leggere joystick/tastiera

                      ; Verifica Pause (Tasto 'P', matrix code 15)
                      LDA $CB
                      CMP #15
                      BNE L0580_NOT_PAUSE
L0580_PAUSE_RELEASE
                      LDA $CB
                      CMP #15
                      BEQ L0580_PAUSE_RELEASE
L0580_PAUSE_LOOP
                      ; Consenti F1 anche mentre si è in pausa!
                      LDA $CB
                      CMP #4         ; F1 key?
                      BEQ L0580_QUICK_RESTART
                      LDA $CB
                      CMP #15        ; Tasto 'P' per riprendere?
                      BNE L0580_PAUSE_LOOP
L0580_RESUME_RELEASE
                      LDA $CB
                      CMP #15
                      BEQ L0580_RESUME_RELEASE
L0580_NOT_PAUSE

                      ; Verifica Quick Restart (Tasto 'F1', matrix code 4)
                      LDA $CB
                      CMP #4
                      BNE L0580_NOT_RESTART
L0580_QUICK_RESTART
                      SEI
                      JSR L0510      ; Ripristina interrupt standard
                      JMP L19D8      ; Torna all inizio del gioco!
L0580_NOT_RESTART

                      LDA #$FF       ; Inizializza stato tasti a rilasciati (tutti 1)
                      STA M03C9

                      ; Verifica Joystick Porta 2 - Sinistra (Bit 2 di CIA1_PRB)
                      LDA CIA1_PRB
                      AND #$04
                      BNE L0580_JOY_NOT_LEFT
                      LDA M03C9
                      AND #$FB       ; Pulisci Bit 2 (Sinistra premuto)
                      STA M03C9
L0580_JOY_NOT_LEFT
                      ; Verifica Joystick Porta 2 - Destra (Bit 3 di CIA1_PRB)
                      LDA CIA1_PRB
                      AND #$08
                      BNE L0580_JOY_NOT_RIGHT
                      LDA M03C9
                      AND #$F7       ; Pulisci Bit 3 (Destra premuto)
                      STA M03C9
L0580_JOY_NOT_RIGHT
                      ; Verifica Joystick Porta 2 - Fuoco (Bit 4 di CIA1_PRB)
                      LDA CIA1_PRB
                      AND #$10
                      BNE L0580_JOY_NOT_FIRE
                      LDA M03C9
                      AND #$FE       ; Pulisci Bit 0 (Fuoco premuto)
                      STA M03C9
L0580_JOY_NOT_FIRE

                      ; Verifica fallback Tastiera tramite codice matrice tasti ($CB)
                      LDA $CB
                      CMP #10        ; Tasto "A" (Sinistra)
                      BNE L0580_KEY_NOT_LEFT
                      LDA M03C9
                      AND #$FB       ; Pulisci Bit 2 (Sinistra)
                      STA M03C9
L0580_KEY_NOT_LEFT
                      LDA $CB
                      CMP #18        ; Tasto "D" (Destra)
                      BNE L0580_KEY_NOT_RIGHT
                      LDA M03C9
                      AND #$F7       ; Pulisci Bit 3 (Destra)
                      STA M03C9
L0580_KEY_NOT_RIGHT
                      LDA $CB
                      CMP #29        ; Tasto "J" (Fuoco)
                      BEQ L0580_KEY_FIRE
                      CMP #60        ; Tasto "Space" (Fuoco)
                      BNE L0580_KEY_NOT_FIRE
L0580_KEY_FIRE
                      LDA M03C9
                      AND #$FE       ; Pulisci Bit 0 (Fuoco)
                      STA M03C9
L0580_KEY_NOT_FIRE

L058D                 LDA M03C9      ; Ripristina stato tasti in accumulatore per compatibilità
                      LDX M03CA
                      ; Bit 2 = sinistra
                      AND #$04
                      BNE L05A1_R
                      CPX #$3F
                      BEQ L05AD
                      INX
                      STX M03CA
L05A1_R               LDA M03C9
                      AND #$08       ; Bit 3 = destra
                      BNE L05AD
                      CPX #$04
                      BEQ L05AD
                      DEX
                      STX M03CA
L05AD                 NOP
                      NOP
                      NOP
                      TXA
                      AND #$01
L05B3                 ASL
                      ASL
                      ASL
                      ASL
                      TAY
                      TXA
                      LSR
                      TAX
L05BB                 LDA SPRDATA_BASE+$80,Y
                      STA $0798,X    ; $8398 -> $0798
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
L05D8                 RTS

; ============================================================================
; PROIETTILE NEMICO
; ============================================================================

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

L09B0                 LDA VIC_RASTER
                      CMP #$80
                      BNE L09B0
                      RTS

L09C0                 LDA VIC_RASTER
                      CMP #$00
                      BEQ L09C0
                      RTS

; ============================================================================
; SETUP TABELLA TIPI
; ============================================================================

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

L09FD                 JSR L0A56
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
                      STA L08F3_SELF+1
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
FREQ_TABLE
  .byte $00,$01,$00,$01,$50,$00,$50,$01
  .byte $00,$01,$50,$00,$00,$01,$00,$00

FREQ_TABLE2
  .byte $13,$03,$0f,$12,$05

FREQ_EFFECT
  .byte $00,$00,$7a,$68,$56,$44,$32,$28
  .byte $10,$15,$28,$36,$40,$48,$4d,$50

; Posizioni invaders (convertite $81FC->$05FC, etc.)
SCRD1000_DATA
  .byte $fc,$05,$f8,$05,$f4,$05,$f0,$05,$ec,$05,$e8,$05,$e4,$05,$e0,$05
  .byte $84,$05,$80,$05,$7c,$05,$78,$05,$74,$05,$70,$05,$6c,$05,$68,$05
  .byte $0c,$05,$08,$05,$04,$05,$00,$05,$fc,$04,$f8,$04,$f4,$04,$f0,$04
  .byte $94,$04,$90,$04,$8c,$04,$88,$04,$84,$04,$80,$04,$7c,$04,$78,$04
  .byte $1c,$04,$18,$04,$14,$04,$10,$04,$0c,$04,$08,$04,$04,$04,$00,$04
  ; Tipi invaders
  .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byte $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
  .byte $03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00

; Indici invaders per colonna
SCRD1100_DATA
  .byte $00,$02,$04,$06,$08,$0a,$0c,$0e,$10,$12,$14,$16,$18,$1a,$1c,$1e
  .byte $20,$22,$24,$26,$28,$2a,$2c,$2e,$30,$32,$34,$36,$38,$3a,$3c,$3e
  .byte $40,$42,$44,$46,$48,$4a,$4c,$4e,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $0e,$0c,$0a,$08,$06,$04,$02,$00,$1e,$1c,$1a,$18,$16,$14,$12,$10
  .byte $2e,$2c,$2a,$28,$26,$24,$22,$20,$3e,$3c,$3a,$38,$36,$34,$32,$30
  .byte $4e,$4c,$4a,$48,$46,$44,$42,$40,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

; Dati sprite (base giocatore, invaders, bonus, costanti)
SPRDATA_BASE
  .byte $20,$20,$6c,$fc,$20,$20,$20,$60,$e1,$e0,$e0,$e0,$60,$60,$00,$00
  .byte $20,$20,$20,$fe,$7b,$20,$20,$60,$60,$e0,$e0,$e0,$61,$60,$00,$00
  .byte $7f,$fe,$6c,$7f,$e2,$7b,$ff,$60,$7f,$fc,$fe,$fe,$ff,$60,$00,$00
  .byte $6c,$7f,$fe,$62,$6c,$6c,$20,$60,$e1,$fc,$fc,$62,$61,$60,$00,$00
  .byte $20,$20,$20,$20,$20,$20,$20,$60,$60,$60,$60,$60,$60,$60,$00,$00
  .byte $20,$20,$20,$20,$20,$20,$20,$20,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  ; Sprite invaders (3 tipi × 2 frame, offset +$80)
  .byte $00,$20,$20,$20,$20,$20,$20,$ff,$e3,$7f,$20,$20,$ff,$f9,$7f,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$fc,$99,$fe,$20,$20,$fb,$20,$ec,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$e9,$f2,$df,$20,$20,$18,$20,$18,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$ff,$e3,$7f,$20,$20,$e1,$f9,$61,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$62,$99,$62,$20,$20,$ec,$62,$fb,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$e9,$f2,$df,$20,$20,$3c,$20,$3e,$20
  .byte $00,$20,$20,$20,$20,$20,$20,$4d,$5d,$2f,$20,$20,$2f,$5d,$4d,$20
  ; Dati punteggi e costanti (offset +$F0)
  .byte $47,$48,$a0,$01,$a0,$02,$a0,$28,$a0,$29,$a0,$2a,$a0,$2b,$a0,$50
  .byte $a0,$51,$a0,$52,$a0,$53,$a0,$78,$a0,$7b,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $05,$2d,$7d,$a5,$a5,$a5,$cd,$cd,$f5,$00,$24,$24,$24,$24,$24,$24
  .byte $20,$e9,$d1,$d1,$d1,$df,$20,$20,$4a,$4b,$20,$4a,$4b,$20,$00,$00
  .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00
  .byte $ff,$ff,$ff,$ff,$10,$ff,$ff,$d0,$ff,$ff,$00,$ff,$ff,$ff,$ff,$00
  .byte $50,$00,$00,$01,$50,$00,$50,$01,$00,$01,$00,$01,$50,$00,$00,$03

; Dati bunker
BUNKER_DATA
  .byte $60,$01,$60,$02,$60,$03,$60,$04,$60,$05,$60,$06,$60,$07,$60,$08
  .byte $60,$09,$60,$0a,$60,$0b,$60,$0c,$60,$0d,$60,$0e,$60,$0f,$60,$10
  .byte $60,$28,$60,$29,$60,$2a,$60,$2b,$60,$2c,$60,$2d,$60,$2e,$60,$2f
  .byte $00

; Dati sprite bonus
BONUS_DATA
  .byte $ff,$ff,$ff,$ff,$10,$ff,$ff,$d0,$ff,$ff,$00,$ff,$ff,$ff,$ff,$00
  .byte $50,$00,$00,$01,$50,$00,$50,$01,$00,$01,$00,$01,$50,$00,$00,$03

; Punteggi e testo
SCRD1300_PTS
  .byte $00,$01,$00,$01,$50,$00,$50,$01,$00,$01,$50,$00,$00,$01,$00,$00

SCRD1300_HIGH
  .byte $20,$e9,$d1,$d1,$d1,$df,$20,$20,$4a,$4b,$20,$4a,$4b,$20,$00,$00
  .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00

SCRD1300_MENU
  .byte $13,$03,$0f,$12,$05,$20,$20,$10,$15,$13,$08,$20,$01,$0e,$19
  .byte $20,$0b,$05,$19,$20,$14,$0f,$20,$13,$14,$01,$12,$14

SCRD1300_MENU2
  .byte $10,$0c,$01,$19,$20,$10,$0c,$01,$19,$05,$12,$20,$31,$20

; GAME OVER TEXT
SCRD1350_TXT
  .byte $13,$11,$11,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
  .byte $1d,$1d,$47,$41,$4d,$45,$20,$4f,$56,$45,$52,$ff

; TRAINER TEXT
SCRD1400_TXT
  .byte $13,$11,$11,$11,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
  .byte $1d,$1d,$1d,$1d,$1d,$50,$4c,$41,$56,$11
  .byte $53,$50,$41,$43,$45,$20,$49,$4e,$56,$41,$44,$45
  .byte $52,$53,$0d,$11,$11,$11,$11,$ff
  .byte $2e,$2e,$2e,$2e,$2e,$2e,$2e,$20,$3f
  .byte $4d,$59,$53,$54,$45,$52,$59,$0d
  .byte $2e,$2e,$2e,$2e,$2e,$2e,$2e,$20
  .byte $33,$30,$20,$50,$4f,$49,$4e,$54,$53
  .byte $2e,$2e,$2e,$2e,$2e,$2e,$2e,$20,$32,$30,$20,$50,$4f,$49,$4e,$54,$53
  .byte $2e,$2e,$2e,$2e,$2e,$2e,$2e,$20,$31,$30,$20,$50,$4f,$49,$4e,$54,$53
  .byte $54,$4f,$50,$20,$31,$35,$30,$30,$20,$50,$4f,$49
  .byte $4e,$54,$53,$20,$46,$4f,$52,$20,$45,$58,$54,$52,$41,$20,$42,$41
  .byte $53,$45,$2e,$ff

; CONTROLS TEXT
SCRD1500_TXT
  .byte $13,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
  .byte $1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
  .byte $4b,$45,$59,$42,$4f,$41,$52,$44,$20,$43,$4f,$4d,$4d,$41,$4e,$44,$53
  .byte $9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d,$9d
  .byte $12,$34,$92,$2d,$4d,$4f,$56,$45,$20,$4c,$45,$46,$54
  .byte $12,$36,$92,$2d,$4d,$4f,$56,$45,$20,$52,$49,$47,$48,$54
  .byte $12,$41,$92,$2d,$46,$49,$52,$45,$20,$42,$45,$41,$4d,$ff

SCRD1500_TRAIN
  .byte $01,$01,$02,$01,$01,$01,$01,$02,$01,$01,$01,$01,$01,$01,$02,$01
  .byte $01,$01,$01,$02,$01,$01,$60,$01,$01,$01,$01,$24,$01,$02,$01,$4d
  .byte $01,$01,$26,$02,$4e,$01,$01,$26,$01,$01,$4e,$01,$01,$26,$01,$01

; SCHERMATA "HOW TO GET SOUND"
SCRD1C00_DATA
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
  .byte $40,$f9,$40,$f9,$40,$f9,$40,$f9,$40,$f9,$40,$f9,$7d,$20,$20,$4e
  .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$01,$20,$02
  .byte $20,$03,$20,$04,$20,$05,$20,$06,$20,$07,$20,$08,$20,$09,$20,$0a
  .byte $4e,$67,$20,$5d,$63,$63,$63,$20,$20,$20,$20,$20,$20,$20,$20,$20
  .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  .byte $20,$20,$20,$20,$20,$20,$20,$67,$20,$67,$20,$5d,$20,$66,$19,$0f
  .byte $15,$12,$20,$10,$05,$14,$20,$20,$20,$66,$66,$66,$66,$66,$66,$66

; ============================================================================
; PATTERN GRAFICI PET PER $60-$7F
; ============================================================================
; Questi pattern vengono copiati a $3800+$300 ($3B00) per sostituire
; i caratteri C64 $60-$7F con i corrispondenti PET.
;
; I pattern sono approssimati per far sì che gli invaders e i bunker
; appaiano correttamente con i dati carattere invariati dal PET.

PET_GRAPHICS_DATA
; pet_char $60 = FULL BLOCK (bunker)
  .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; pet_char $61 = UPPER HALF
  .byte $FF,$FF,$FF,$FF,$00,$00,$00,$00
; pet_char $62 = LOWER HALF
  .byte $00,$00,$00,$00,$FF,$FF,$FF,$FF
; pet_char $63 = LEFT HALF (usato negli sprite invader)
  .byte $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
; pet_char $64 = RIGHT HALF
  .byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
; pet_char $65 = CHECKERBOARD
  .byte $AA,$55,$AA,$55,$AA,$55,$AA,$55
; pet_char $66 = FULL CHECKER (inverso)
  .byte $55,$AA,$55,$AA,$55,$AA,$55,$AA
; pet_char $67 = DIAMOND
  .byte $18,$3C,$7E,$FF,$FF,$7E,$3C,$18
; pet_char $68 = VERT STRIPE LEFT
  .byte $88,$88,$88,$88,$88,$88,$88,$88
; pet_char $69 = VERT STRIPE RIGHT
  .byte $22,$22,$22,$22,$22,$22,$22,$22
; pet_char $6A = SMALL DIAMOND
  .byte $18,$3C,$7E,$18,$18,$7E,$3C,$18
; pet_char $6B = VERT LINE
  .byte $81,$81,$81,$81,$81,$81,$81,$81
; pet_char $6C = MEDIUM SQUARE (usato sprite)
  .byte $7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E
; pet_char $6D = CROSS
  .byte $81,$81,$81,$FF,$FF,$81,$81,$81
; pet_char $6E = TOP LEFT CORNER
  .byte $FF,$80,$80,$80,$80,$80,$80,$80
; pet_char $6F = TOP RIGHT CORNER
  .byte $FF,$01,$01,$01,$01,$01,$01,$01
; pet_char $70 = BOT LEFT CORNER
  .byte $80,$80,$80,$80,$80,$80,$80,$FF
; pet_char $71 = BOT RIGHT CORNER
  .byte $01,$01,$01,$01,$01,$01,$01,$FF
; pet_char $72 = LEFT VERT THICK
  .byte $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
; pet_char $73 = RIGHT VERT THICK
  .byte $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
; pet_char $74 = UPPER THICK
  .byte $FF,$FF,$FF,$FF,$00,$00,$00,$00
; pet_char $75 = LOWER THICK
  .byte $00,$00,$00,$00,$FF,$FF,$FF,$FF
; pet_char $76 = HORIZ THICK
  .byte $FF,$FF,$00,$00,$00,$00,$FF,$FF
; pet_char $77 = VERT THICK
  .byte $99,$99,$99,$99,$99,$99,$99,$99
; pet_char $78 = SMALL BLOCK
  .byte $7E,$7E,$7E,$7E,$00,$00,$00,$00
; pet_char $79 = HALF CHECKER (usato sprite invader)
  .byte $AA,$55,$AA,$55,$00,$00,$00,$00
; pet_char $7A = MEDIUM CHECKER
  .byte $AA,$55,$AA,$55,$55,$AA,$55,$AA
; pet_char $7B = VERT STRIPE (usato sprite)
  .byte $CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC
; pet_char $7C = SMALL HORIZ (usato sprite)
  .byte $FF,$FF,$00,$00,$00,$00,$00,$00
; pet_char $7D = SMALL VERT
  .byte $C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3
; pet_char $7E = ANTI-DIAGONAL (usato sprite)
  .byte $81,$42,$24,$18,$18,$24,$42,$81
; pet_char $7F = DIAGONAL (usato sprite invader)
  .byte $18,$24,$42,$81,$81,$42,$24,$18

; ============================================================================
; END OF FILE
; ============================================================================
