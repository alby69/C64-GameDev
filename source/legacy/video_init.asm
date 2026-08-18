; ****************************************************************************
; video_init.asm
; ****************************************************************************
; Purpose: VIC-II video initialization, custom charset copier, and "How To Get Sound" splash screen handler.
; ****************************************************************************
START
                      ; --- PAL/NTSC AUTO-DETECTION ---
#ifdef NTSC
                      LDA #$01
                      STA SYSTEM_TYPE
#else
#ifdef PAL
                      LDA #$00
                      STA SYSTEM_TYPE
#else
                      ; Store 1 (NTSC) by default
                      LDA #$01
                      STA SYSTEM_TYPE

                      ; Wait for raster to be in top area (< 256)
L_DET_WAIT_TOP        LDA $D011
                      AND #$80
                      BNE L_DET_WAIT_TOP

                      ; Wait for raster to reach line 0
L_DET_WAIT_L0         LDA VIC_RASTER
                      BNE L_DET_WAIT_L0

                      ; Count and loop over a frame
                      LDX #$FF
L_DET_OUTER           LDY #$FF
L_DET_INNER           LDA $D011
                      AND #$80
                      BEQ L_DET_NEXT
                      LDA VIC_RASTER
                      CMP #$1E        ; If line is >= 256 + 30 = 286, it's PAL
                      BCC L_DET_NEXT
                      LDA #$00        ; PAL detected
                      STA SYSTEM_TYPE
L_DET_NEXT            DEY
                      BNE L_DET_INNER
                      DEX
                      BNE L_DET_OUTER
#endif
#endif

                      ; --- Initialize SYNC_LINE_VAL ---
                      LDA #$80        ; Sync line $80 for PAL
                      LDX SYSTEM_TYPE
                      BEQ L_INIT_SYNC
                      LDA #$60        ; Sync line $60 for NTSC
L_INIT_SYNC           STA SYNC_LINE_VAL

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
