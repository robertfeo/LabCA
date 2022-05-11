; export symbols
        XDEF  delay_0_5sec
              
; Defines
IMAX:   EQU     2048                ; Constant declaration
            
; ROM: Assembler program code in RAM
.init: SECTION

;##########################################
; delay_0_5sec: Busy waiting for 0,5sec (at Frequency of 24MHz)
; Parameter: -
; Return:    -
; Registers: Unchanged
delay_0_5sec:
         PSHX
         PSHY
                  
         LDX  #IMAX                      ; Initialisiert das X-Register mit der symbolischen Konstanten
waitO:   LDY  #IMAX                      ; Initialisiert das Y-Register mit der symbolischen Konstanten
waitI:   DBNE Y, waitI                   ; Dekrementiert Y und springt zu "waitI" falls Wert ungleich null ist
         DBNE X, waitO                   ; Dekrementiert Y und springt zu "waitO" falls Wert ungleich null ist
         
         PULY
         PULX
         RTS                             ; Springt zurück in die aufrufende Funktion