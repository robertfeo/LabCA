               
; export symbols
        XDEF  initClock , tickClock, timeToString, toggleMode
        XDEF  secsAdd, minsAdd, hrsAdd
        XDEF  setMode
        
; include derivative specific macros         
        XREF writeLine, decToASCII, calcTemp, toggleLED

; Defines
SELECT12HOURS:   equ    0
  
; RAM: Variable data section
.data:  SECTION
hrs:      ds.b 1
mins:     ds.b 1
secs:     ds.b 1
time:     ds.b 19 ;"HH:MM:SSpm " -> 11 Zeichen mit Nullterminierung + temperatur
tempStr:  ds.b 7
setMode:  ds.b 1

 ;**************************************************************
; Public interface function: initClock ... Anfangsuhrzeit initialisieren 
; Parameter: -
; Return:    -
; Registers: -

; 0Uhr, nicht 24Uhr eingeben 
 initClock:
            MOVB #00, hrs
            MOVB #59, mins         
            MOVB #30, secs
            RTS 
            
 ;**************************************************************
; Public interface function: tickClock ... bei Aufruf hochz?hlen und ?berlauf pr?fen  
; Parameter: -
; Return:    einen String mit der Uhrzeit
; Registers: -
tickClock:  
            PSHA
            LDAA secs
            CMPA #59
            BHS secsOFL         ; nach overflow ?berpr?fen
            JSR secsAdd
            BRA finish
            
secsOFL: 
            LDAA mins
            CMPA #59
            BHS minsOFL
            JSR secsAdd
            JSR minsAdd
            bra finish

minsOFL: 
            JSR hrsAdd
            JSR minsAdd
            JSR secsAdd 
finish: 
            PULA 
            JSR timeToString
            RTS
            
 ;**************************************************************
; Public interface function: secsAdd ... Sekunden +1
; Parameter: -
; Return:    -
; Registers: -
secsAdd: 
            PSHA
            LDAA secs
            CMPA #59
            BHS  secsOF
           
            INC secs
            BRA secsFinish
secsOF:     MOVB #0, secs        ; bei overflow auf 0 zur?ck
            
secsFinish: 
            PULA
            RTS
            
 ;**************************************************************
; Public interface function: minsAdd ... Minuten +1
; Parameter: -
; Return:    -
; Registers: -
minsAdd: 
            PSHA
            LDAA mins
            CMPA #59
            BHS  minsOF
            INC mins
            BRA minsFinish
    minsOF: MOVB #0, mins
minsFinish: 
            PULA
            RTS
            
  ;**************************************************************
; Public interface function: hrsAdd ... Stunden+1
; Parameter: -
; Return:    -
; Registers: - 
hrsAdd: 
            PSHA
            LDAA hrs
            CMPA #23
            BHS  hrsOF
            INC  hrs
            BRA  hrsFinish
    hrsOF:  MOVB #0, hrs
hrsFinish: 
            PULA
            RTS
          
;**************************************************************
; Public interface function: timeToString: mit dectoascii wird in string umgewandelt 
; Parameter: -
; Return:    String mit Uhrzeit (und Temperatur im n?chsten Schritt)
; Registers: -  
  IFGT SELECT12HOURS      
timeToString:
            PSHX
            PSHY
            PSHD
           
            LDX  #tempStr            ; temp string f?r dectoascii rechnung
            LDY  #time               ; richtige Uhrzeit
            PSHY
            LDAA #$00
            LDAB hrs
            BEQ midnight             ; bei 23 wird hrs auf 0 gesetzt, dann muss hrs bei 12 am weiter gehen
            CMPB #12
            BLS hrsStr
            SUBB #12
            BRA hrsStr 

     midnight: 
            LDD #12
     hrsStr: 
            JSR decToASCII
            JSR null
            MOVB #58, 1, Y+          ; Doppelpunkt dazu
            
            LDAB mins
            JSR  decToASCII
            JSR null

            MOVB #58, 1, Y+
            
            LDAB secs
            JSR  decToASCII
            JSR null

            LDAB hrs
            CMPB #12
            BGE P

            MOVB #$61, 1, Y+
            BRA  M
         P: MOVB #$70, 1, Y+
         M: MOVB #$6D, 1, Y+  
            ;MOVB #$20, 1, Y+   


            MOVB #$20, 1, Y+
            MOVB #$20, 1, Y+
            
            jsr calcTemp
            
            PULY
            TFR Y, X                 ; weil writeLine x register nutzt
            
            LDAB #1
            jsr writeLine 
            
            PULD
            PULY
            PULX
            RTS
   ELSE
timeToString:   
            PSHX
            PSHY
            PSHD
           
            LDX  #tempStr
            LDY  #time
            PSHY
            LDAA #$00
            LDAB hrs
            JSR  decToASCII
            
            JSR null
            MOVB #58, 1, Y+
            
            LDAB mins
            JSR  decToASCII
            
            JSR null
            MOVB #58, 1, Y+
            
            LDAB secs
            JSR  decToASCII
            
            JSR null
            MOVB #$20, 1, Y+   


            MOVB #$20, 1, Y+
            MOVB #$20, 1, Y+
            
            jsr calcTemp
            
            PULY
            TFR Y, X                     
            
            LDAB #1
            jsr writeLine 
            
            PULD
            PULY
            PULX
            RTS
  ENDIF
            


;**************************************************************
; Public interface function:um f?hrende Nullen zu entfernen
; Parameter: X ... pointer auf den Zahlenstring
;            Y ... pointer auf das n?chste Zeichen im string
; Return:    -
; Registers: Y-Reg wird hochgez?hlt je nach geschriebenen Zeichen
;            B-Reg ?ndert sich, aber nicht mehr n?tigt      
null:     
            LDAB 4, X
            CMPB #$30
            BEQ  nulltrue
            MOVB 4, X, 1, Y+
            BRA  nullfalse
nulltrue:   MOVB #$20, 1, Y+
nullfalse:  MOVB 5, X, 1, Y+  
            RTS
    
;**************************************************************
; Public interface function: toggleMode ... Konvertiert einen 16 bit Wert in einen dec string
; Parameter: X: zeigt auf string
;            D: speichert wert
; Return:    String value in RAM-Memory (on X-Reg adress)
; Registers: Unchanged
toggleMode: 
            PSHB
            LDAB setMode
            EORB #$01
            STAB setMode
            LDAB #$80
            JSR  toggleLED
            PULB
            RTS 

 