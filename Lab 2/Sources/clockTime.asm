
; export symbols
        XDEF

        
; RAM: Variable data section
.data:  SECTION
hrs:    ds.b 1
mins:   ds.b 1
secs:   ds.b 1
time:   ds.b 11 ;"HH:MM:SSpm " -> 11 Zeichen mit Nullterminierung
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
; ROM: Constant data
.const:SECTION  

; ROM: Code section
.init:  SECTION

;**************************************************************
; Public interface function: initClock ... Initialisiert die Uhr auf die Anfangsuhrzeit und den Normal Mode
; Parameter: -
; Return:    -
; Registers: Unchanged
; Error checks:
;   none
initClock:
            MOVB #11, hrs
            MOVB #59, mins
            MOVB #30, secs
            MOVB #$00, setMode
            RTS                  ; Springt zurück in die aufrufende Funktion

;**************************************************************
; Public interface function: tickClock ... Zählt die Uhr bei jedem Aufruf hoch und erzeugt einen String
; Parameter: -
; Return:    String Variable in RAM-Memory (auf der Adresse der Variable "time")
; Registers: Unchanged
; Error checks:
;   Überlauft des Sekunden, Minuten, Stunden counter von 59 bzw. 24 auf 0            
tickClock:  
            PSHA
            LDAA secs
            CMPA #59
            BHS  SECSOF
            JSR  plusSecs
            BRA  ende
            
   SECSOF:  LDAA mins
            CMPA #59
            BHS  MINSOF
            JSR  plusSecs
            JSR  plusMins
            BRA  ende
            
   MINSOF:  JSR  plusHrs
            JSR  plusMins
            JSR  plusSecs
                         
            
      ende: PULA
            JSR calcTime  
            RTS
            
;**************************************************************
; Public interface function: plusSecs ... Erhöht den Sekunden counter mit 60sec Überlauf
; Parameter: -
; Return:    -
; Registers: Unchanged
; Error checks:
; 
plusSecs:
            PSHA
            LDAA secs
            CMPA #59
            BHS  secsOF
            INC  secs
            BRA  secsExit
    secsOF: MOVB #0, secs
  secsExit: PULA    
            RTS

;**************************************************************
; Public interface function: plusMins ... Erhöht den Minuten counter mit 60min Überlauf
; Parameter: -
; Return:    -
; Registers: Unchanged
; Error checks:
; 
plusMins:   
            PSHA
            LDAA mins
            CMPA #59
            BHS  minsOF
            INC  mins
            BRA  minsExit
    minsOF: MOVB #0, mins
  minsExit: PULA    
            RTS
 
;**************************************************************
; Public interface function: plusHrs ... Erhöht den Stunden counter mit 24h Überlauf
; Parameter: -
; Return:    -
; Registers: Unchanged
; Error checks:
; 
plusHrs:    
            PSHA
            LDAA hrs
            CMPA #23
            BHS  hrsOF
            INC  hrs
            BRA  hrsExit
     hrsOF: MOVB #0, hrs
   hrsExit: PULA    
            RTS
  
;**************************************************************
; Public interface function: calcTime ... Konvertiert die Counter-Werte in einen String
; Parameter: -
; Return:    String Variable in RAM-Memory (auf der Adresse der Variable "time")
; Registers: Unchanged
; Error checks:
;   none
calcTime:   PSHX
            PSHY
            PSHD
           
            LDX  #tempStr
            LDY  #time
            LDAA #$00
            LDAB hrs
            JSR  decToASCII
            
            MOVB 4, X, 1, Y+
            MOVB 5, X, 1, Y+
            MOVB #58, 1, Y+
            
            LDAB mins
            JSR  decToASCII
            
            MOVB 4, X, 1, Y+
            MOVB 5, X, 1, Y+
            MOVB #58, 1, Y+
            
            LDAB secs
            JSR  decToASCII
            
            MOVB 4, X, 1, Y+
            MOVB 5, X, 1, Y+
            MOVB #0, 1, Y+
            
            PULD
            PULY
            PULX
            RTS

;**************************************************************
; Public interface function: toggleMode ... Converts a 16-Bit value into an equal dec-string
; Parameter: X ... pointer to string
;            D ... holds the value
; Return:    String value in RAM-Memory (on X-Reg adress)
; Registers: Unchanged
; Error checks:
;   none            
toggleMode: 
            PSHB
            LDAB setMode
            EORB #$01
            STAB setMode
            LDAB #$80
            JSR  toggleLED
            PULB
            RTS 
            
            
            