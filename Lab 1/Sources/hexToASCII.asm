; export symbols
        XDEF hexToASCII
        
; RAM: Variable data section
.data:  SECTION   

; ROM: Constant data
.const: SECTION
H2A: DC.B "0123456789ABCDEF"

; ROM: Code section
.init:  SECTION

;**************************************************************
; Public interface function: hexToASCII ... Converts a 16-Bit value into hex-string
; Parameter: X ... pointer to string
;            D ... holds the value
; Return:    String value in RAM-Memory (on Reg-X adress)
; Registers: Unchanged
hexToASCII:
    PSHX
    PSHY
    PSHD

    MOVB #$30, 1, X+    ; X Register auf Wert '0' setzen
    MOVB #$78, 1, X+
    
    LSRA                ; shift right 4 bits, high nibble => 0
    LSRA                ;
    LSRA                ;
    LSRA                ;
    
    ;1. nibble          ; index as offset in constant section H2A
    TFR A, Y            ; transfer value of Reg-A in Pointer-Reg-Y
    LDAB H2A, Y         ; interpret char from H2A using Pointer-Reg-Y into Reg-B
    STAB 1, X+          ; save value of Reg-B in string
    
    ; 2. nibble
    LDD 0, SP           ; restore Reg-D
    ANDA #$0F           ; "deactivate" Higher Value Nibbles
    TFR A, Y            ;
    LDAB H2A, Y         ;
    STAB 1, X+          ;
    
    ; 3. nibble
    LDD 0, SP           ;
    LSRB                ; 
    LSRB                ;
    LSRB                ;
    LSRB                ;
    TFR B, Y            ;
    LDAA H2A, Y         ;
    STAA 1, X+          ;
    
    ; 4. nibble
    LDD 0, SP           ;
    ANDB #$0F           ;
    TFR B, Y            ;
    LDAA H2A, Y         ;
    STAA 1, X+          ;
    
    MOVB #$00, X        ; 
    
    PULD
    PULY
    PULX
    RTS
