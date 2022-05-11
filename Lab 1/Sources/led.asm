; export symbols
        XDEF initLED, setLED, getLED, toggleLED

; include derivative specific macros
        INCLUDE 'mc9s12dp256.inc'

; ROM: Code section
.init:  SECTION

;**************************************************************
; Public interface function: initLED ... initializes Data Direction Register on Port B and turns it off
; Parameter: X ... pointer to string
;            D ... holds the value
; Return:    String value in RAM-Memory (on Reg-X adress)
; Registers: Unchanged
initLED:
            BSET DDRJ, #2                   ; bit Set:   Port J.1 as output
            BCLR PTJ,  #2                   ; bit Clear: J.1=0 --> Activate LEDs
            MOVB #$0F, DDRP                 ; port for 7-Seg Display as output ports
            MOVB #$0F, PTP                  ; turn off all segments
            MOVB #$FF, DDRB                 ; set port for LEDs as output
            MOVB #$00, PORTB                ; turn off all LEDs
            RTS                             ; return to caller function
            
;**************************************************************
; Public interface function: setLED ... sets the LEDs as given in Reg-B
; Parameter: B ... holds the LED-vector
; Return:    -
; Registers: Unchanged     
setLED:
            STAB PORTB                      ; set LEDs based on value from Reg-B
            RTS                             ; return to caller function

;**************************************************************
; Public interface function: getLED ... saves settings of current LED in Reg-B
; Parameter: -
; Return:    B ... hold the current LED settings
; Registers: B ... changed          
getLED:     
            LDAB PORTB                      ; loads status of LED in Reg-B
            RTS                             ; return to caller function

;**************************************************************
; Public interface function: toggleLED ... toggles the states of the LEDs given by B-Register
; Parameter: B ... holds the bit-vector 
; Return:    -
; Registers: unchanged
toggleLED:
            PSHB
            EORB  PORTB                     ; save new bits in Reg-B
            STAB  PORTB                     ; load content of Reg-B on the LEDs
            PULB
            RTS                             ; return to caller function
            
            