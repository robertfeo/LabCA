
; export symbols	   
        XDEF initADC, convertADC , value

  ; include derivative specific macros
       INCLUDE 'mc9s12dp256.inc'
  ; Defines

; RAM: Variable data section
.data: SECTION
value:       DS.W 1                ; Measurement value

; ROM: Constant data
.const:SECTION                     

; ROM: Interrupt vector entries
.vect: SECTION
        ORG $FFD2
int22:  DC.W isrATD0               ; Interruptvector for interrupt 22 (ATD0)

; ROM: Code section
.init: SECTION

 ;**************************************************************
; Public interface function: initThermo ... Initialisiert mit den Parametern
; Parameter: -
; Return:    -
; Registers: -

initADC:
            MOVB #%11000010, ATD0CTL2     ; Enable ATD0, enable interrupt
            MOVB #%00100000, ATD0CTL3     ; Sequence: 4 measurements
            MOVB #%00000101, ATD0CTL4     ; 10bit, 2MHz ATD0 clock

            MOVB #%10000111, ATD0CTL5     ; Start first measurement on single channel 7
            RTS
;**************************************************************
; Public interface function: ändern der Temperatur
; Parameter: -
; Return:    -
; Registers: -
convertADC:  
            BSET ATD0CTL2, #$01
            MOVB #%10000111, ATD0CTL5
            RTS
            
            


;********************************************************************
; Internal function: isrATD0 ... Interrupt service routine, von ATD0 aufgerufen
; Parameter: -
; Return:    Liest den ATD0 aus und speichert den Wert in die Variable value
; Error checks:
;   Unterschied zwischen Simulation und Monitoring
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

