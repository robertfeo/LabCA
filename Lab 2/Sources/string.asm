; export symbols
        XDEF strCpy, strCat

; Defines

; RAM: Variable data section
.data: SECTION

; ROM: Constant data
.const: SECTION

; ROM: Code section
.init: SECTION

;**************************************************************
; Public interface function: strCpy ... String wird an andere Adresse kopiert
; Parameter: X ... Pointer auf Ausgangs-String
;            Y ... Pointer auf neuen Speicherort
; Return:    String wurde an Speicheradresse von REG-Y geschrieben
; Registers: unchanged
; Error checks:
;   Nullterminierung am Stringende ist obligatrisch            
strCpy:
            PSHB          ; Sichern des B-Registers auf Stack
            PSHX          ; Sichern des X-Registers auf Stack
            PSHY          ; Sichern des Y-Registers auf Stack
            
        B0: LDAB 1, X+    ; Laden des Zeichens an Adresse X in B-Register und anschliesend (1 Byte) inkrementieren 
            STAB 1, Y+    ; Speichern des Zeichens in B-Register an Adresse Y und anschliesend (1 Byte) inkrementieren 
            CMPB #$00     ; Falls Zeichen gleich nullterminierung: Routine beenden
            BEQ  B4
            BRA  B0       ; Sonst naechstes Zeichen kopieren
            
        B4: PULY          ; Y-Register wieder herstellen
            PULX          ; X-Register wieder herstellen
            PULB          ; B-Register wieder herstellen
            RTS           ; Springt zur?ck in die aufrufende Funktion            

;**************************************************************
; Public interface function: strCat ... String in Y-Reg wird an String in X-Reg angehangen 
; Parameter: X ... Pointer auf zu verl?ngernden String
;            Y ... Pointer auf anzuh?ngenden String
;            B ... Anzahl der Leerzeichen zwischen den Strings
; Return:    String in Y-Reg wurde an String in X-Reg angehangen
; Registers: unchanged
; Error checks:
;            Nullterminierungen an den Stringenden ist obligatrisch
;            Die L?nge des Gesamt-Strings wird nicht ermittelt!!
;            -> Schreiben auf nicht allokierten Speicher wird nicht ?berpr?ft      
strCat:
            PSHD
            PSHX
            PSHY         
            
     xNext: LDAA 0, X
            BEQ  xStrEnd
            INX
            BRA  xNext
            
   xStrEnd: CMPB #0
            BLE  spaceRdy
            MOVB #$20, 1, X+
            DECB
            BRA  xStrEnd
            
  spaceRdy: EXG  X, Y
            JSR  strCpy
            
            PULY
            PULX
            PULD
            RTS