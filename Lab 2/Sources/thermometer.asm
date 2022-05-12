  IFNDEF _HCS12_SERIALMON
    IFNDEF SIMULATOR 
SIMULATOR: EQU 1
    ENDIF
  ENDIF

; export symbols	   
        XDEF initThermo, updateTemp, calcTemp
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
tempStr:     DS.B 7                 ; '-00000 ' -> 7 Zeichen

 Org $100f

temperature: DS.B 6                 ; '-00°C ' -> 6 Zeichen
;xRegisterVar DS.B 7
;yRegisterVar DS.B 6
; ROM: Constant data
.const:SECTION                     

; ROM: Interrupt vector entries
.vect: SECTION
        ORG $FFD2
int22:  DC.W isrATD0                ; Interruptvector for interrupt 22 (ATD0)

; ROM: Code section
.init: SECTION

;**************************************************************
; Public interface function: initThermo ... Initialisiert den AD-Koverter mit den Parametern
; Parameter: -
; Return:    -
; Registers: Unchanged
; Error checks:
;   none
initThermo:
            MOVB #%11000010, ATD0CTL2     ; Enable ATD0, enable interrupt
            MOVB #%00100000, ATD0CTL3     ; Sequence: 4 measurements
            MOVB #%00000101, ATD0CTL4     ; 10bit, 2MHz ATD0 clock

            MOVB #%10000111, ATD0CTL5     ; Start first measurement on single channel 7
            RTS

;********************************************************************
; Internal function: isrATD0 ... Interrupt service routine, called by the ATD0
; Parameter: -
; Return:    Liest den ATD0 aus und speichert den Wert in die Variable value
; Error checks:
;   Unterscheided zwischen Simulation und Monitoring in der Funktion des Interrupts
isrATD0:  
            LDD  ATD0DR0                  ; Read the result registers,
            ADDD ATD0DR1                  ; ... compute average of 4 measurements
            ADDD ATD0DR2
            ADDD ATD0DR3
  IFDEF SIMULATOR
            LDD  value
            ADDD #30
            CPD  #1024
            BLS  finish
            LDD  #0
    finish:         
  ELSE
            LSRD
            LSRD
  ENDIF
            STD  value                    ; ... and store the result
            RTI                           ; Return from interrupt service routine

;**************************************************************
; Public interface function: startConv ... Startet die ATD Konvertierung für Konveter 0
; Parameter: -
; Return:    -
; Registers: Unchanged
; Error checks:
;   none
updateTemp:  
            BSET ATD0CTL2, #$01
            MOVB #%10000111, ATD0CTL5
            RTS

;**************************************************************
; Public interface function: calcTemp ... Wandelt den Zahlenwert in einen String
; Parameter: -
; Return:    String in Variable 'temperature'
; Registers: Unchanged
; Error checks:
;   none
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

   IFDEF SELECT12HOURS
            ;MOVB #$6D, 1, Y+      ;m
            MOVB #$20, 1, Y+
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
            MOVB #248, 1, Y+                ; ASCII '°' in String schreiben
            MOVB #67, 1, Y+                 ; ASCII 'C' in String schreiben
            MOVB #0, 1, Y+                  ; Nullterminieren
            
            
           ; PULY
           ; TFR Y, X                       ; weil writeLine x register nutzt
            ;INCY
           ; LDAB #1
           ; jsr writeLine 

            
            PULD
            PULY

            PULX
            RTS
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
            MOVB #6F, 1, Y+                 ; ASCII '°' in String schreiben
            MOVB #67, 1, Y+                 ; ASCII 'C' in String schreiben
            MOVB #0, 1, Y+                  ; Nullterminieren
            
            
           ; PULY
           ; TFR Y, X                       ; weil writeLine x register nutzt
            ;INCY
           ; LDAB #1
           ; jsr writeLine 

            
            PULD
            PULY

            PULX
            RTS
       ENDIF