               
; export symbols
        XDEF  initClock , tickClock, timeToString, toggleMode
        XDEF  secsAdd, minsAdd, hrsAdd
        XDEF  setMode
        
; include derivative specific macros         
        XREF writeLine, decToASCII, calcTemp, toggleLED

; Defines
SELECT12HOURS:   equ    1
  
; RAM: Variable data section
.data:  SECTION
hrs:      ds.b 1
mins:     ds.b 1
secs:     ds.b 1
time:     ds.b 19 ;"HH:MM:SSpm " -> 11 Zeichen mit Nullterminierung
tempStr:  ds.b 7
setMode:  ds.b 1

 ;**************************************************************
; Public interface function: initClock ... Anfangsuhrzeit initialisieren 
; Parameter: -
; Return:    -
; Registers: Unchanged
 initClock:
            MOVB #11, hrs
            MOVB #59, mins         
            MOVB #30, secs
            RTS 
            
 ;**************************************************************
; Public interface function: tickClock ... bei Aufruf hochz�hlen und �berlauf pr�fen  
; Parameter: -
; Return:    einen String mit der Uhrzeit
; Registers: Unchanged
tickClock:  
            PSHA
            LDAA secs
            CMPA #59
            BHS secsOFL         ; nach overflow �berpr�fen
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
; Registers: Unchanged
secsAdd: 
            PSHA
            LDAA secs
            CMPA #59
            BHS  secsOF
           
            INC secs
            BRA secsFinish
secsOF:     MOVB #0, secs        ; bei overflow auf 0 zur�ck
            
secsFinish: 
            PULA
            RTS
            
 ;**************************************************************
; Public interface function: minsAdd ... Minuten +1
; Parameter: -
; Return:    -
; Registers: Unchanged
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
; Registers: Unchanged 
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
; Return:    String mit Uhrzeit
; Registers: Unchanged  
  IFGT SELECT12HOURS      
timeToString:
            PSHX
            PSHY
            PSHD
           
            LDX  #tempStr            ; temp string f�r dectoascii rechnung
            LDY  #time               ; richtige Uhrzeit
            PSHY
            LDAA #$00
            LDAB hrs
            BEQ  midnight
            CMPB #12
            BLS  hrsStr
            SUBB #12
            BRA  hrsStr
     midnight: 
            LDD #12
     hrsStr: 
            JSR decToASCII
            
            
            ; hrs 1006 und 1007
            
            JSR null
            ; MOVB 4, X, 1, Y+
            ; MOVB 5, X, 1, Y+
            MOVB #58, 1, Y+          ; Doppelpunkt dazu
            
            LDAB mins
            JSR  decToASCII
            ; mins 10A
            JSR null

            ; MOVB 4, X, 1, Y+
            ; MOVB 5, X, 1, Y+
            MOVB #58, 1, Y+
            
            LDAB secs
            JSR  decToASCII
            JSR null
            ; MOVB 4, X, 1, Y+
            ; MOVB 5, X, 1, Y+
            LDAB hrs
            CMPB #12
            BEQ P
            ; CMPB #1
            ; BEQ P
            MOVB #$61, 1, Y+
            BRA  M
         P: MOVB #$70, 1, Y+
         M: MOVB #$6D, 1, Y+  
            MOVB #$20, 1, Y+   


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
            TFR Y, X                      ; weil writeLine x register nutzt
            
            LDAB #1
            jsr writeLine 
            
            PULD
            PULY
            PULX
            RTS
  ENDIF
            


;**************************************************************
; Public interface function: null ... Kopiert den Wert aus dem Zahlenstring in den Textstring
; Parameter: X ... pointer auf den Zahlenstring
;            Y ... pointer auf das n�chste Zeichen im Textstring
; Return:    -
; Registers: Y-Reg wird hochgez�hlt abh�ngig von den geschriebenen Zeichen
;            B-Reg �ndert sich, aber wird nicht mehr ben�tigt      
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
; Public interface function: toggleMode ... Converts a 16-Bit value into an equal dec-string
; Parameter: X ... pointer to string
;            D ... holds the value
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

 