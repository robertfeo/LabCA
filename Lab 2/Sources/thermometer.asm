  IFNDEF _HCS12_SERIALMON
    IFNDEF SIMULATOR 
SIMULATOR: EQU 1
    ENDIF
  ENDIF

; export symbols	   
        XDEF  calcTemp
        XDEF temperature

; import symbols
        XREF decToASCII, writeLine
        
   SELECT12HOURS:   equ    1



; include derivative specific macros
       INCLUDE 'mc9s12dp256.inc'
       
; Defines 
maxTemp    equ    70                ; Maximal messbarer Wert
minTemp    equ   -30                ; Minimal messbarer Wert
max        equ  1023                ; Maximaler Sensorwert bei 10-Bit Auflösung
range      equ  maxTemp-minTemp     ; Wertebereich des Anzeigewerts    

; RAM: Variable data section
.data: SECTION
value:       DS.W 1                 ; Measurement value
tempStr:     DS.B 7                  

 Org $100f

temperature: DS.B 6                 
;xRegisterVar DS.B 7
;yRegisterVar DS.B 6
; ROM: Constant data
.const:SECTION                     

; ROM: Interrupt vector entries

; ROM: Code section
.init: SECTION



;**************************************************************
; Public interface function: Wandelt den Zahlenwert in einen String
; Parameter: -
; Return:    String in Variable 'temperature'
; Registers: -

calcTemp:   
            PSHX
            PSHY
            PSHD
            
              
            LDD  value
            LDY  #range               ; Temperatur °C berechnen
            EMUL                      ; x*100
            LDX  #max                   
            EDIV                      ; (x*100)/1023
            TFR  Y, D
            ADDD #minTemp             ; ((x*100)/1023)-30
            LDX #tempStr
            ;PULY in variable adresse vin y register schreiben
            ;LDY $1008
            ;puly
           
            STY temperature
            LDY #temperature

            JSR decToASCII

  IFGT SELECT12HOURS      
            MOVB #$6D, 1, Y+      ;m
            MOVB #$20, 1, Y+
            MOVB #$20, 1, Y+

            LDAB 4, X
            CMPB #$30
            BEQ  istNull
           ; MOVB 0, X, 1, Y+
            MOVB 4, X, 1, Y+
            BRA  next
   istNull: MOVB #$20, 1, Y+
            MOVB 0, X, 1, Y+ 
      next: MOVB 5, X, 1, Y+
            MOVB #248, 1, Y+                ; ASCII '°' in String schreiben
            MOVB #67, 1, Y+                 ; ASCII 'C' in String schreiben
            MOVB #0, 1, Y+                  ; Nullterminieren


            
            PULD
            PULY

            PULX
            RTS
  ; jz ohne m:
  else
            MOVB #$20, 1, Y+

            LDAB 4, X
            CMPB #$30
            BEQ  istNull
            MOVB 0, X, 1, Y+
            MOVB 4, X, 1, Y+
            BRA  next
   istNull: MOVB #$20, 1, Y+
            MOVB 0, X, 1, Y+ 
      next: MOVB 5, X, 1, Y+
            MOVB #$6F, 1, Y+                 ; ASCII '°' in String schreiben
            MOVB #67, 1, Y+                 ; ASCII 'C' in String schreiben
            MOVB #0, 1, Y+                  ; Nullterminieren

            PULD
            PULY

            PULX
            RTS
       ENDIF