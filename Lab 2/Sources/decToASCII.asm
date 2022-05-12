; export symbols
        XDEF decToASCII

; RAM: Variable data section
.data:  SECTION

; ROM: Constant data
.const: SECTION

; ROM: Code section
.init:  SECTION

;**************************************************************
; Public interface function: decToASCII ... konvertiert 16 bit Wert in dec string
; Parameter: X ... pointer auf string
;            D ... speichert value
; Return:    String value in RAM-Memory (x zeigt drauf)
; Registers: Unchanged
decToASCII:        
    PSHX                        ; secure Registers
    PSHY                        ;
    PSHD                        ;
    TFR  X, Y                   ; Reg-X needed, so string in Reg-Y
    
    TSTA                        ; check if content of Reg-A is negative
    BMI  negativeValue          ; if negative:
    MOVB #$20, 1, Y+            ; write ' ' in string
    BRA  divide                 ; else:
negativeValue: 
    MOVB #$2D, 1, Y+            ; write '-' in string
    COMA                        ; one's complement
    COMB                        ; two's complement
    INCB                        ; two's complement
divide:
    LDX   #10000                ; set divider at 10000
    IDIV                        ; divide Reg-X with Reg-D
    EXG   X, D                  ; exchange values between X(Result) and D(Remainder)
    ADDB  #48                   ; save char in string
    STAB  1, Y+                 ;
                           
    TFR   X, D                  ; grab back remainder in Reg-D
    LDX   #1000                 ; set divider at 1000
    IDIV                        ;
    EXG   X, D                  ;
    ADDB  #48                   ;
    STAB  1, Y+                 ;
                       
    TFR   X, D                  ;
    LDX   #100                  ; set divider at 100
    IDIV                        ;
    EXG   X, D                  ;
    ADDB  #48                   ;
    STAB  1, Y+                 ;
                 
    TFR   X, D                  ;
    LDX   #10                   ; set divider at 10
    IDIV                        ;
    EXG   X, D                  ;
    ADDB  #48                   ;
    STAB  1, Y+                 ;
                                 
    TFR   X, D                  ;
    ADDB  #48                   ;
    STAB  1, Y+                 ; save remainder of the division in string
    
    MOVB #$00, Y                ; terminating NUL
    
    PULD                        ; restore registers
    PULY                        ;
    PULX                        ;
    RTS                         ; return to caller function