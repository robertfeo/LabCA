;
;   Labor 1 - Task 3.2
;
;   Computerarchitektur
;   Hochschule Esslingen
;
;   Author:   	   Selina Moritz, Robert Fesko
;   (based on template provided by J.Friedrich and W.Zimmermann)
;   Last Modified: R.Fesko, Apr 23, 2022

; Export symbols
        XDEF Entry, main

; Import symbols
        XREF __SEG_END_SSTACK                   ; End of stack
        XREF initLCD, writeLine, delay_10ms     ; LCD functions
        XREF decToASCII, hexToASCII             ; Convert functions
        XREF delay_0_5sec                       ; delay function
        XREF initLED,setLED,getLED, toggleLED   ; LED functions

; Include derivative specific macros
        INCLUDE 'mc9s12dp256.inc'

; Defines

; RAM: Variable data section
.data:  SECTION
value:  DC.W 0
string  DC.B 7

; ROM: Constant data
.const: SECTION

; ROM: Code section
.init:  SECTION

main:
Entry:
        LDS  #__SEG_END_SSTACK          ; Initialize stack pointer
        CLI                             ; Enable interrupts, needed for debugger

        JSR  delay_10ms                 ; Delay 20ms during power up
        JSR  delay_10ms
        
        JSR  initLCD                    ; Initialize the LCD
        JSR  initLED                    ; Initialize the LED 
        LDX  #string                    ; Pointer fuer ToACSII und write Funktionen
        MOVW #$0000, value              ; 
        MOVB #$00, DDRH                 ; Port H as inputs

program:   
        LDD  value                      ; Load current index into Register D
        JSR  decToASCII                 ; Convert Reg-D Dec to string
        PSHB                            ; 
        LDAB #0                         ; Write content of Reg-B in LCD Line 0
        JSR  writeLine                  ;
        PULB                            ; 
        JSR  hexToASCII                 ; Convert Reg-D Hex to string
        PSHB                            ; 
        LDAB #1                         ; Write content of Reg-B in LCD Line 1
        JSR  writeLine                  ; 
        PULB                            ;
        JSR  setLED                     ; Set LEDs with content of Reg-B
        JSR  delay_0_5sec               ; 
        BRCLR PTH, #$01, plus16         ; If Button 0 -> index plus 16
        BRCLR PTH, #$04, minus16        ; If Button 2 -> index minus 16
        BRCLR PTH, #$02, plus10         ; If Button 1 -> index plus 10
        BRCLR PTH, #$08, minus10        ; If Button 3 -> index minus 10  
        ADDD #1                         ; else index plus 1
                                        
                                        ; (S)tore (T)hen (B)ranch
    STB:STD  value                      ; Store index
        BRA  program                    ; Branch to program
    
plus16: ADDD #16                       
        BRA  STB
        
minus16:SUBD #16
        BRA  STB
        
plus10: ADDD #10
        BRA  STB
        
minus10:SUBD #10
        BRA  STB 
        
        




