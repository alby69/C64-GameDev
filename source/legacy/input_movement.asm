; ****************************************************************************
; input_movement.asm
; ****************************************************************************
; Purpose: Keyboard matrix scanning and joystick Port 2 reading to control player base.
; ****************************************************************************
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

                      ; --- NEUTRALIZE JOYSTICK DIAGONAL ---
                      LDA CIA1_PRB
                      AND #$03
                      CMP #$03
                      BEQ L0580_NO_DIAG   ; No vertical input -> not a diagonal
                      LDA CIA1_PRB
                      AND #$0C
                      CMP #$0C
                      BEQ L0580_NO_DIAG   ; No horizontal input -> not a diagonal
                      JMP L0580_JOY_NOT_RIGHT ; Neutralize: skip left and right checks
L0580_NO_DIAG

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
                      LDA FIRE_DEBOUNCE_TIMER
                      BNE L0580_JOY_NOT_FIRE ; Skip if fire button debounced
                      LDA CIA1_PRB
                      AND #$10
                      BNE L0580_JOY_NOT_FIRE
                      LDA M03C9
                      AND #$FE       ; Pulisci Bit 0 (Fuoco premuto)
                      STA M03C9
                      LDA #4
                      STA FIRE_DEBOUNCE_TIMER
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

                      ; Verifica fallback Tastiera - Fuoco
                      LDA FIRE_DEBOUNCE_TIMER
                      BNE L0580_KEY_NOT_FIRE ; Skip if fire button debounced
                      LDA $CB
                      CMP #29        ; Tasto "J" (Fuoco)
                      BEQ L0580_KEY_FIRE
                      CMP #60        ; Tasto "Space" (Fuoco)
                      BNE L0580_KEY_NOT_FIRE
L0580_KEY_FIRE
                      LDA M03C9
                      AND #$FE       ; Pulisci Bit 0 (Fuoco)
                      STA M03C9
                      LDA #4
                      STA FIRE_DEBOUNCE_TIMER
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
